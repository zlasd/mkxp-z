// Standalone regression for the production PhysFS RGSS archive readers.
#include "rgssad.h"
#include <cassert>
#include <cstdint>
#include <cstdio>
#include <fstream>
#include <string>
#include <vector>

using Bytes = std::vector<uint8_t>;
static void word(Bytes &out, uint32_t value) {
    for (int i = 0; i < 4; ++i) out.push_back(value >> (i * 8));
}
static Bytes fixture(bool fux, uint32_t nameLength, uint32_t offset,
                     uint32_t size = 11) {
    const char *header = fux ? "Fux2Pack" : "RGSSAD\0\3";
    Bytes out(header, header + 8);
    const uint32_t seed = 0xdeadbeef;
    const uint32_t key = seed * 9 + 3;
    word(out, fux ? key : seed);
    word(out, offset ^ key);
    word(out, size ^ key);
    word(out, 0x12345678 ^ key);
    word(out, nameLength ^ key);
    const std::string name = "Data\\Scripts.rvdata2";
    // The normal fixture uses the actual filename length and resulting offset.
    for (size_t i = 0; i < name.size(); ++i)
        out.push_back(uint8_t(name[i]) ^ uint8_t(key >> ((i % 4) * 8)));
    word(out, key); // encrypted zero offset ends the index
    uint32_t magic = 0x12345678;
    for (uint32_t i = 0; i < 11; ++i) {
        out.push_back(uint8_t(i * 23) ^ uint8_t(magic >> ((i % 4) * 8)));
        if (i % 4 == 3) magic = magic * 7 + 3;
    }
    return out;
}

int main(int argc, char **argv) {
    assert(argc == 2 && PHYSFS_init(argv[0]));
    assert(PHYSFS_registerArchiver(&RGSS1_Archiver));
    assert(PHYSFS_registerArchiver(&RGSS2_Archiver));
    assert(PHYSFS_registerArchiver(&RGSS3_Archiver));
    const std::string path = std::string(argv[1]) + "/fixture.rgss3a";
    auto mount = [&](const Bytes &bytes, bool expected) {
        std::ofstream file(path, std::ios::binary | std::ios::trunc);
        file.write(reinterpret_cast<const char *>(bytes.data()), bytes.size());
        file.close();
        assert(bool(PHYSFS_mount(path.c_str(), nullptr, 1)) == expected);
    };
    const uint32_t length = std::string("Data\\Scripts.rvdata2").size();
    const uint32_t offset = 12 + 16 + length + 4;
    for (bool fux : {false, true}) {
        mount(fixture(fux, length, offset), true);
        PHYSFS_File *file = PHYSFS_openRead("Data/Scripts.rvdata2");
        assert(file && PHYSFS_fileLength(file) == 11);
        uint8_t bytes[20];
        assert(PHYSFS_readBytes(file, bytes, sizeof(bytes)) == 11);
        for (int i = 0; i < 11; ++i) assert(bytes[i] == uint8_t(i * 23));
        assert(PHYSFS_seek(file, 3));
        assert(PHYSFS_readBytes(file, bytes, 5) == 5);
        for (int i = 0; i < 5; ++i) assert(bytes[i] == uint8_t((i + 3) * 23));
        assert(PHYSFS_seek(file, 9));
        assert(PHYSFS_readBytes(file, bytes, sizeof(bytes)) == 2);
        assert(bytes[0] == uint8_t(9 * 23) && bytes[1] == uint8_t(10 * 23));
        assert(PHYSFS_readBytes(file, bytes, sizeof(bytes)) == 0);
        assert(PHYSFS_close(file));
        assert(PHYSFS_unmount(path.c_str()));
        for (size_t count : {size_t(7), size_t(10), size_t(20), size_t(30)}) {
            Bytes truncated = fixture(fux, length, offset);
            truncated.resize(count);
            mount(truncated, false);
        }
        mount(fixture(fux, 512, offset), false);
        mount(fixture(fux, 0, offset), false);
        mount(fixture(fux, length, 0xfffffff0, 0x40), false);
    }
    Bytes unknown = fixture(true, length, offset);
    unknown[7] = 'X';
    mount(unknown, false);
    std::remove(path.c_str());
    assert(PHYSFS_deinit());
    puts("RGSS3/Fux2Pack reads, seeks, and malformed archives passed");
}
