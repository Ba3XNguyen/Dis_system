import com.rabbitmq.client.AMQP;
import com.rabbitmq.client.Channel;
import com.rabbitmq.client.Connection;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.UUID;
import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;

public final class RPCClient implements AutoCloseable {
    private final Connection connection;
    private final Channel channel;
    private final String replyQueueName;
    private final BlockingQueue<String> responses = new ArrayBlockingQueue<>(1);
    private volatile String pendingId;
    private final long timeoutMs;

    public RPCClient() throws IOException, TimeoutException {
        this(Long.parseLong(RpcConfig.env("RPC_TIMEOUT_MS", "60000")));
    }
    public RPCClient(long timeoutMs) throws IOException, TimeoutException {
        if (timeoutMs <= 0) throw new IllegalArgumentException("timeout must be positive");
        this.timeoutMs = timeoutMs;
        connection = RpcConfig.factory().newConnection();
        Channel opened;
        String callbackQueue;
        try {
            opened = connection.createChannel();
            opened.queueDeclare(RpcConfig.queue(), false, false, false, null);
            // Mot hang doi callback rieng cho moi client, dung lai cho cac call.
            callbackQueue = opened.queueDeclare("", false, true, true, null).getQueue();
            opened.basicConsume(callbackQueue, true, (tag, delivery) -> {
                if (delivery.getProperties().getCorrelationId() != null &&
                    delivery.getProperties().getCorrelationId().equals(pendingId)) {
                    responses.offer(new String(delivery.getBody(), StandardCharsets.UTF_8));
                }
            }, tag -> { });
        } catch (IOException | RuntimeException ex) {
            connection.close();
            throw ex;
        }
        channel = opened;
        replyQueueName = callbackQueue;
        System.out.println("Callback queue: " + replyQueueName);
    }
    // Mot client nay thuc hien lan luot; nhieu process client van chay song song.
    public synchronized String call(String message) throws IOException, InterruptedException, TimeoutException {
        String corrId = UUID.randomUUID().toString();
        responses.clear();
        pendingId = corrId;
        try {
            AMQP.BasicProperties props = new AMQP.BasicProperties.Builder()
                    .correlationId(corrId)
                    .replyTo(replyQueueName)
                    .contentType("text/plain")
                    .build();
            // Default exchange route theo dung ten hang doi rpc_queue.
            channel.basicPublish("", RpcConfig.queue(), props, message.getBytes(StandardCharsets.UTF_8));
            String answer = responses.poll(timeoutMs, TimeUnit.MILLISECONDS);
            if (answer == null) throw new TimeoutException("No reply after " + timeoutMs + "ms; correlationId=" + corrId);
            return answer;
        } finally {
            pendingId = null;
        }
    }
    @Override public void close() throws IOException { connection.close(); }
    public static void main(String[] args) {
        try (RPCClient client = new RPCClient()) {
            if (args.length == 0) {
                for (int n = 0; n < 32; n++) show(client, Integer.toString(n));
            } else {
                for (String n : args) show(client, n);
            }
        } catch (InterruptedException ex) {
            Thread.currentThread().interrupt();
            System.err.println("Client interrupted");
            System.exit(1);
        } catch (IOException | TimeoutException | IllegalArgumentException ex) {
            System.err.println("RPC client: " + ex.getMessage());
            System.exit(1);
        }
    }
    private static void show(RPCClient client, String n) throws IOException, InterruptedException, TimeoutException {
        long started = System.nanoTime();
        System.out.println("[x] Requesting fib(" + n + ")");
        String answer = client.call(n);
        System.out.printf("[.] Got '%s' (%d ms)%n", answer, (System.nanoTime() - started) / 1000000);
    }
}
