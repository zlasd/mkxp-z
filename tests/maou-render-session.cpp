// Standalone: clang++ -std=c++11 -pthread tests/maou-render-session.cpp -o /tmp/maou-render-session
#include "../src/maou_render_session.h"
#include <cassert>
#include <thread>
#include <cstdio>

int main() {
    MaouRenderSession session;
    assert(!session.begin(0));
    assert(!session.begin(UINT64_MAX));
    assert(!session.cancel(0));
    assert(!session.cancel(1));
    assert(!session.finish(1));
    for (uint64_t generation = 1; generation <= 10000; ++generation) {
        assert(session.begin(generation));
        assert(!session.begin(generation + 1));
        assert(session.state(generation) == 1);
        std::thread stale([&] {
            for (int n = 0; n < 100; ++n) {
                assert(!session.cancel(generation - 1));
                assert(!session.finish(generation - 1));
            }
        });
        assert(session.cancel(generation));
        assert(session.cancel(generation));
        stale.join();
        assert(session.cancelled());
        assert(session.state(generation) == 2);
        assert(session.finish(generation));
        assert(!session.cancel(generation));
        assert(!session.cancelled());
        assert(session.state(generation) == 0);
    }
    std::puts("PASS: 10000 render generations; stale cancellation cannot replace active state");
}
