// multiply by 4 the slow way
int mul4_original(int a) {
    return a * 4;
}

// multiply by 4 via shift (optimization)
int mul4_optimized(int a) {
    return a << 2;
}
