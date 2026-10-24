import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.Callable;
import java.util.concurrent.Executors;

// Can broker va RPCServer dang chay, khong chay chung voi server delay 2s.
public final class RpcIntegrationTest {
    public static void main(String[] args) throws Exception {
        try (RPCClient client = new RPCClient(15000)) {
            for (int n = 0; n < 32; n++) {
                String result = client.call(Integer.toString(n));
                if (!result.equals(Long.toString(Fibonacci.fib(n)))) throw new AssertionError("fib " + n);
            }
            for (String bad : new String[]{"abc", "-1", "93"}) {
                if (!client.call(bad).startsWith("ERROR:")) throw new AssertionError("invalid: " + bad);
            }
        }
        var pool = Executors.newFixedThreadPool(3);
        try {
            List<Callable<Boolean>> jobs = new ArrayList<>();
            for (int i = 0; i < 3; i++) jobs.add(() -> {
                try (RPCClient client = new RPCClient(15000)) { return client.call("20").equals("6765"); }
            });
            for (var result : pool.invokeAll(jobs)) if (!result.get()) throw new AssertionError("concurrent client");
        } finally { pool.shutdownNow(); }
        System.out.println("PASS: 32 fib requests, 3 invalid requests, 3 concurrent clients");
    }
}
