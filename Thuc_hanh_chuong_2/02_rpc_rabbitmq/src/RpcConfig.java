import com.rabbitmq.client.ConnectionFactory;

final class RpcConfig {
    static String queue() { return env("RPC_QUEUE", "rpc_queue"); }
    static String env(String key, String fallback) {
        String value = System.getenv(key);
        return value == null || value.isEmpty() ? fallback : value;
    }
    static ConnectionFactory factory() {
        ConnectionFactory factory = new ConnectionFactory();
        factory.setHost(env("RABBITMQ_HOST", "localhost"));
        factory.setPort(Integer.parseInt(env("RABBITMQ_PORT", "5672")));
        factory.setUsername(env("RABBITMQ_USER", "guest"));
        factory.setPassword(env("RABBITMQ_PASSWORD", "guest"));
        factory.setVirtualHost(env("RABBITMQ_VHOST", "/"));
        factory.setConnectionTimeout(10000);
        // Demo fail fast; restart app sau khi broker bi khoi dong lai.
        factory.setAutomaticRecoveryEnabled(false);
        return factory;
    }
    private RpcConfig() { }
}
