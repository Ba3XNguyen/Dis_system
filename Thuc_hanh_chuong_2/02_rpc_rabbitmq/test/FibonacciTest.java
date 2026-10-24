public final class FibonacciTest {
    public static void main(String[] args) {
        int cases = 0;
        long[] first = {0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55};
        for (int i = 0; i < first.length; i++) {
            if (Fibonacci.fib(i) != first[i]) throw new AssertionError("fib " + i);
            cases++;
        }
        if (Fibonacci.fib(31) != 1346269L) throw new AssertionError("fib31"); cases++;
        if (Fibonacci.fib(92) != 7540113804746346429L) throw new AssertionError("fib92"); cases++;
        for (int n : new int[]{-1,93}) {
            try { Fibonacci.fib(n); throw new AssertionError("accepted " + n); }
            catch (IllegalArgumentException expected) { cases++; }
        }
        System.out.println("PASS: " + cases + " Fibonacci cases (no broker needed)");
    }
}
