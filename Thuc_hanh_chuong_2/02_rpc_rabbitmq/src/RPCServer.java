import com.rabbitmq.client.AMQP;
import com.rabbitmq.client.Channel;
import com.rabbitmq.client.Connection;
import java.nio.charset.StandardCharsets;
import java.util.concurrent.CountDownLatch;

public final class RPCServer {
    public static void main(String[] args) throws Exception {
        long delayMs = 0;
        if (args.length == 2 && args[0].equals("--delay-ms")) delayMs = Long.parseLong(args[1]);
        else if (args.length != 0) throw new IllegalArgumentException("Usage: RPCServer [--delay-ms 2000]");
        if (delayMs < 0 || delayMs > 10000) throw new IllegalArgumentException("delay-ms must be 0..10000");
        final long delay = delayMs;
        CountDownLatch stop = new CountDownLatch(1);
        try (Connection connection = RpcConfig.factory().newConnection(); Channel channel = connection.createChannel()) {
            // Khong purge de khoi dong lai server khong xoa cac yeu cau dang cho.
            channel.queueDeclare(RpcConfig.queue(), false, false, false, null);
            channel.basicQos(1);
            channel.confirmSelect();
            connection.addShutdownListener(cause -> stop.countDown());
            Runtime.getRuntime().addShutdownHook(new Thread(stop::countDown));
            channel.basicConsume(RpcConfig.queue(), false, (tag, delivery) -> {
                String request = new String(delivery.getBody(), StandardCharsets.UTF_8);
                String answer;
                try {
                    int n = Integer.parseInt(request);
                    answer = Long.toString(Fibonacci.fib(n));
                    if (delay > 0) Thread.sleep(delay);
                } catch (InterruptedException ex) {
                    Thread.currentThread().interrupt();
                    channel.basicNack(delivery.getEnvelope().getDeliveryTag(), false, true);
                    return;
                } catch (IllegalArgumentException ex) {
                    answer = "ERROR: expected integer n in 0..92";
                }
                AMQP.BasicProperties replyProps = new AMQP.BasicProperties.Builder()
                        .correlationId(delivery.getProperties().getCorrelationId())
                        .contentType("text/plain")
                        .build();
                String replyTo = delivery.getProperties().getReplyTo();
                if (replyTo == null || replyTo.isEmpty()) {
                    System.err.println("Reject request without replyTo");
                    channel.basicReject(delivery.getEnvelope().getDeliveryTag(), false);
                    return;
                }
                try {
                    channel.basicPublish("", replyTo, replyProps, answer.getBytes(StandardCharsets.UTF_8));
                    channel.waitForConfirmsOrDie(5000);
                    // Chi ack request sau khi broker da xac nhan nhan ban publish.
                    channel.basicAck(delivery.getEnvelope().getDeliveryTag(), false);
                    System.out.printf("fib(%s) = %s; correlationId=%s%n", request, answer, replyProps.getCorrelationId());
                } catch (Exception ex) {
                    System.err.println("Reply failed: " + ex.getMessage());
                    if (channel.isOpen()) channel.basicNack(delivery.getEnvelope().getDeliveryTag(), false, true);
                }
            }, tag -> stop.countDown());
            System.out.printf("Awaiting RPC requests: queue=%s, prefetch=1, delay=%dms%n", RpcConfig.queue(), delay);
            stop.await();
        }
    }
}
