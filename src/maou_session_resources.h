#ifndef MAOU_SESSION_RESOURCES_H
#define MAOU_SESSION_RESOURCES_H
#include <algorithm>
#include <cstdint>
#include <unordered_map>
#include <vector>

struct MaouResourceReport {
    uint64_t tracked = 0, live = 0, released = 0, failures = 0, pooledBytes = 0;
};

// Owned by the render thread. Entries are non-owning: dispose releases the
// resource, while its Ruby wrapper can be finalized later without a double free.
// Serial numbers prevent an address reused during disposal from matching an
// earlier snapshot. Destructors may remove other entries during the sweep.
template<class T> class MaouSessionResources {
    struct Entry { uint64_t generation, serial; };
    std::unordered_map<T *, Entry> entries;
    uint64_t serial = 0, closedThrough = 0;
public:
    bool add(T *object, uint64_t generation) {
        if (generation && generation <= closedThrough) return false;
        entries[object] = {generation, ++serial};
        return true;
    }
    void remove(T *object) { entries.erase(object); }
    MaouResourceReport inspect(uint64_t generation) const {
        MaouResourceReport report;
        for (const auto &entry : entries) if (entry.second.generation == generation) {
            ++report.tracked;
            if (!entry.first->isDisposed()) ++report.live;
        }
        return report;
    }
    MaouResourceReport release(uint64_t generation) {
        MaouResourceReport report;
        if (!generation) { report.failures = 1; return report; }
        closedThrough = std::max(closedThrough, generation);
        std::vector<std::pair<uint64_t, T *>> snapshot;
        for (const auto &entry : entries) if (entry.second.generation == generation)
            snapshot.emplace_back(entry.second.serial, entry.first);
        std::sort(snapshot.rbegin(), snapshot.rend());
        for (const auto &entry : snapshot) {
            auto current = entries.find(entry.second);
            if (current == entries.end() || current->second.serial != entry.first) continue;
            try {
                if (!entry.second->isDisposed()) { entry.second->dispose(); ++report.released; }
            } catch (...) { ++report.failures; } // Continue releasing independent resources.
        }
        const auto remaining = inspect(generation);
        report.live = remaining.live; report.tracked = remaining.tracked;
        return report;
    }
};
#endif
