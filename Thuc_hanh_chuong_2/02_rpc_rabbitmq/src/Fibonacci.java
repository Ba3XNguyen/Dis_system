final class Fibonacci {
    static long fib(int n) {
        if (n < 0 || n > 92) throw new IllegalArgumentException("n must be in 0..92 (long)");
        if (n == 0) return 0;
        long previous = 0, current = 1;
        for (int i = 2; i <= n; i++) {
            long next = previous + current;
            previous = current;
            current = next;
        }
        return current;
    }
    private Fibonacci() { }
}
