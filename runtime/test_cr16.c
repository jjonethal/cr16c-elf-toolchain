// test_cr16.c
int compute(int a, int b) {
    return (a * 2) + b;
}

// The standard entry point for your application
int main(void) {
    volatile int result = 0;
    
    while (1) {
        // Call your compute function inside an infinite loop
        result = compute(5, 10);
    }
    
    return 0; // Will never be reached
}
