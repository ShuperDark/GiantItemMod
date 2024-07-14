#include "substrate.h"
#include <string>
#include <cstdio>
#include <chrono>
#include <memory>
#include <vector>
#include <mach-o/dyld.h>
#include <stdint.h>
#include <cstdlib>
#include <sys/mman.h>
#include <sys/stat.h>
#include <random>
#include <cstdint>
#include <unordered_map>
#include <map>
#include <functional>
#include <cmath>
#include <chrono>
#include <libkern/OSCacheControl.h>
#include <cstddef>
#include <tuple>
#include <mach/mach.h>
#include <mach-o/getsect.h>
#include <mach-o/loader.h>
#include <mach-o/nlist.h>
#include <mach-o/reloc.h>

#include <dlfcn.h>

#include "glm/glm.hpp"
#include "glm/gtc/matrix_transform.hpp"

#import <Foundation/Foundation.h>
#import "UIKit/UIKit.h"

struct TextureUVCoordinateSet;
struct CompoundTag;
struct Material;
struct BlockSource;
struct PlayerInventoryProxy;
struct ItemInHandRenderer;
struct InGamePlayScreen;

enum class MaterialType : int {
	DEFAULT = 0,
	DIRT,
	WOOD,
	STONE,
	METAL,
	WATER,
	LAVA,
	PLANT,
	DECORATION,
	WOOL = 11,
	BED,
	FIRE,
	SAND,
	DEVICE,
	GLASS,
	EXPLOSIVE,
	ICE,
	PACKED_ICE,
	SNOW,
	CACTUS = 22,
	CLAY,
	PORTAL = 25,
	CAKE,
	WEB,
	CIRCUIT,
	LAMP = 30,
	SLIME
};

enum class BlockSoundType : int {
	NORMAL, GRAVEL, WOOD, GRASS, METAL, STONE, CLOTH, GLASS, SAND, SNOW, LADDER, ANVIL, SLIME, SILENT, DEFAULT, UNDEFINED
};

enum class CreativeItemCategory : unsigned char {
	BLOCKS = 1,
	DECORATIONS,
	TOOLS,
	ITEMS
};

struct Block
{
	void** vtable;
	char filler[0x90-8];
	int category;
	char filler2[0x94+0x19+0x90-4];
};

struct Item {
    void** vtable; // 0
    uint8_t maxStackSize; // 8
    int idk; // 12
    std::string atlas; // 16
    int frameCount; // 40
    bool animated; // 44
    short itemId; // 46
    std::string name; // 48
    std::string idk3; // 72
    bool isMirrored; // 96
    short maxDamage; // 98
    bool isGlint; // 100
    bool renderAsTool; // 101
    bool stackedByData; // 102
    uint8_t properties; // 103
    int maxUseDuration; // 104
    bool explodeable; // 108
    bool shouldDespawn; // 109
    bool idk4; // 110
    uint8_t useAnimation; // 111
    int creativeCategory; // 112
    float idk5; // 116
    float idk6; // 120
    char buffer[12]; // 124
    TextureUVCoordinateSet* icon; // 136
    char filler[176 - 144];

    struct Tier {
        int level;
        int uses;
        float speed;
        int damage;
        int enchantmentValue;
    };
};

struct WeaponItem : public Item {
    int damage;
    Item::Tier* tier;
};

struct DiggerItem : public Item {
    float speed; // 0xb4
    Item::Tier* tier; // 0xc0
    int attackDamage; // 0xc4
    char filler[0x1E0-0xC4];
};

struct PickaxeItem : public DiggerItem {};

struct BlockItem :public Item {
	char filler[0xB0];
};

struct ItemInstance {
	uint8_t count;
	uint16_t aux;
	CompoundTag* tag;
	Item* item;
	Block* block;
	int idk[3];
};

struct BlockGraphics {
	void** vtable;
	char filler[0x20 - 8];
	int blockShape;
	char filler2[0x3C0 - 0x20 - 4];
};

struct LevelData {
	char filler[48];
	std::string levelName;
	char filler2[44];
	int time;
	char filler3[144];
	int gameType;
	int difficulty;
};

struct Level {
	char filler[160];
	LevelData* data;
};

struct Entity {
	char filler[64];
	Level* level;
	char filler2[104];
	BlockSource* region;
};

struct Player :public Entity {
	char filler[4400];
	PlayerInventoryProxy* inventory;
};

struct Vec3 {
	float x, y, z;

	Vec3(float _x, float _y, float _z) : x(_x), y(_y), z(_z) {}

	float distanceTo(float _x, float _y, float _z) const {

		return (float) sqrt((x - _x) * (x - _x) + (y - _y) * (y - _y) + (z - _z) * (z - _z));
	}

	float distanceTo(Vec3 const& v) const {

		return distanceTo(v.x, v.y, v.z);
	}

	bool operator!=(Vec3 const& other) const {
		return x == other.x || y == other.y || z == other.z;
	}

	bool operator==(Vec3 const& other) const {
        return x == other.x && y == other.y && z == other.z;
    }

    Vec3 operator+(Vec3 const& v) const {
    	return {this->x + v.x, this->y + v.y, this->z + v.z};
    }

    Vec3 operator-(Vec3 const& v) const {
    	return {this->x - v.x, this->y - v.y, this->z - v.z};
    }

    Vec3 operator-() const {
    	return {-x, -y, -z};
    }

    Vec3 operator*(float times) const {
    	return {x * times, y * times, z * times};
    };

    Vec3 operator/(float value) const {
    	return {x / value, y / value, z / value};
    };

    Vec3 operator*(Vec3 const& v) const {
    	return {x * v.x, y * v.y, z * v.z};
    }
};

struct BlockPos {
	int x, y, z;

	BlockPos() : BlockPos(0, 0, 0) {}

    BlockPos(int x, int y, int z) : x(x), y(y), z(z) {}

    BlockPos(Vec3 const &v) : x((int) floorf(v.x)), y((int) floorf(v.y)), z((int) floorf(v.z)) {}

    BlockPos(BlockPos const &blockPos) : BlockPos(blockPos.x, blockPos.y, blockPos.z) {}

    bool operator==(BlockPos const &pos) const {
        return x == pos.x && y == pos.y && z == pos.z;
    }
    bool operator!=(BlockPos const &pos) const {
        return x != pos.x || y != pos.y || z != pos.z;
    }
    bool operator<(BlockPos const& pos) const {
        return std::make_tuple(x, y, z) < std::make_tuple(pos.x, pos.y, pos.z);
    }

	BlockPos getSide(unsigned char side) const {
        switch (side) {
            case 0:
                return {x, y - 1, z};
            case 1:
                return {x, y + 1, z};
            case 2:
                return {x, y, z - 1};
            case 3:
                return {x, y, z + 1};
            case 4:
                return {x - 1, y, z};
            case 5:
                return {x + 1, y, z};
            default:
                return {x, y, z};
        }
	}
};

struct Matrix {
    glm::mat4x4 matrix;

    Matrix() : matrix(glm::mat4x4(1)) {}

    void rotate(float angle, Vec3 const &v) {
        matrix = glm::rotate(matrix, (float) (angle * M_PI / 180.f), glm::vec3(v.x, v.y, v.z));
    };

    void translate(Vec3 const &v) {
        matrix = glm::translate(matrix, glm::vec3(v.x, v.y, v.z));
    };

    void scale(Vec3 const & v) {
        matrix = glm::scale(matrix, glm::vec3(v.x, v.y, v.z));
    };
};

struct MatrixStack {
    struct Ref {
        MatrixStack* stack;
        Matrix* matrix;
        Ref() : stack(nullptr), matrix(nullptr) {}
        Ref(MatrixStack& stack, Matrix& matrix) : stack(&stack), matrix(&matrix) {}
        Ref(MatrixStack::Ref&& x) : stack(x.stack), matrix(x.matrix) {
            x.stack = nullptr;
            x.matrix = nullptr;
        }
        ~Ref() {
            if (stack)
                stack->pop();
        }
        Ref& operator=(MatrixStack::Ref&& x) {
            stack = x.stack;
            matrix = x.matrix;
            x.stack = nullptr;
            x.matrix = nullptr;
            return *this;
        }
        Matrix* operator*() { return matrix; }
    };

    std::vector<Matrix> stack;
    bool dirty = false;

    Matrix* _push() { stack.emplace_back(stack.back()); return &stack.back(); }
    Ref push() { dirty = true; return Ref(*this, *_push()); }
    void pop() { stack.pop_back(); dirty = true; }
    Ref getTop() { return Ref(*this, stack.back()); }

    static MatrixStack* Projection;
    static MatrixStack* World;
    static MatrixStack* View;
};
MatrixStack* MatrixStack::Projection;
MatrixStack* MatrixStack::World;
MatrixStack* MatrixStack::View;

namespace Json { class Value; }

static Item*** Item$mItems;
static Item::Tier* Item$Tier$STONE;
static void** WeaponItem$vtable;

static Item*(*Item$Item)(Item*, std::string const&, short);
static Item*(*Item$setIcon)(Item*, std::string const&, int);
static Item*(*Item$setHandEquipped)(Item*);
static Item*(*Item$setMaxStackSize)(Item*, unsigned char);
static Item*(*Item$setMaxDamage)(Item*, int);
static void(*Item$addCreativeItem)(ItemInstance const&);

static PickaxeItem*(*PickaxeItem$PickaxeItem)(PickaxeItem*, std::string const&, int, Item::Tier const&);

static ItemInstance*(*ItemInstance$ItemInstance)(ItemInstance*, int, int, int);
static int(*ItemInstance$getId)(ItemInstance const*);

int giantSword = 1000;
int giantPickaxe = 1001;

static bool isFirstPerson = false;

WeaponItem* giantSwordPtr;
PickaxeItem* giantPickaxePtr;

static void (*_Item$initCreativeItems)();
static void Item$initCreativeItems() {
	_Item$initCreativeItems();

	ItemInstance giantsword_inst;
	ItemInstance$ItemInstance(&giantsword_inst, giantSword, 1, 0);
	Item$addCreativeItem(giantsword_inst);

	ItemInstance giantpickaxe_inst;
	ItemInstance$ItemInstance(&giantpickaxe_inst, giantPickaxe, 1, 0);
	Item$addCreativeItem(giantpickaxe_inst);
}

static void (*_Item$registerItems)();
static void Item$registerItems() {
	_Item$registerItems();

	giantSwordPtr = new WeaponItem();
	Item$Item(giantSwordPtr, "giantsword", giantSword - 0x100);
	giantSwordPtr->vtable = WeaponItem$vtable;
	Item$mItems[1][giantSword] = giantSwordPtr;
	giantSwordPtr->creativeCategory = 3;
	giantSwordPtr->damage = 12;
    giantSwordPtr->tier = Item$Tier$STONE;
	Item$setHandEquipped(giantSwordPtr);
	Item$setMaxStackSize(giantSwordPtr, 1);
	Item$setMaxDamage(giantSwordPtr, 1024);

	giantPickaxePtr = new PickaxeItem();
	PickaxeItem$PickaxeItem(giantPickaxePtr, "giantpickaxe", giantPickaxe - 0x100, *Item$Tier$STONE);
	Item$mItems[1][giantPickaxe] = giantPickaxePtr;
	giantPickaxePtr->creativeCategory = 3;
	giantPickaxePtr->attackDamage = 10;
	Item$setHandEquipped(giantPickaxePtr);
	Item$setMaxStackSize(giantPickaxePtr, 1);
	Item$setMaxDamage(giantPickaxePtr, 1024);
}

static void (*_Item$initClientData)();
static void Item$initClientData() {
	_Item$initClientData();

	Item$setIcon(giantSwordPtr, "sword", 1);

	Item$setIcon(giantPickaxePtr, "pickaxe", 1);
}

static std::string (*_I18n$get)(std::string const&);
static std::string I18n$get(std::string const& key) {

	if(key == "item.giantsword.name")
		return "Giant's Sword";
	if(key == "item.giantpickaxe.name")
		return "Giant's Pickaxe";

	return _I18n$get(key);
}

static void (*_ItemInHandRenderer$renderItem)(ItemInHandRenderer*, Entity&, ItemInstance const&, bool, float);
static void ItemInHandRenderer$renderItem(ItemInHandRenderer* self, Entity& entity, ItemInstance const& item, bool b, float f) {
    auto m = MatrixStack::World->push();
    if(ItemInstance$getId(&item) == giantSword || ItemInstance$getId(&item) == giantPickaxe) {
	    if (!isFirstPerson) {
	        (*m)->translate({0.65f, 1.5f, 0.2f});
	        (*m)->scale(Vec3(4.25f, 4.25f, 4.25f));
	    } else {
	        (*m)->translate(Vec3(-0.5f, 0.f, -0.2f));
	        (*m)->scale(Vec3(1.7f, 1.7f, 1.7f));
	    }
	}
    _ItemInHandRenderer$renderItem(self, entity, item, b, f);
}

static void (*_InGamePlayScreen$_renderItemInHand)(InGamePlayScreen*, Player&, bool, float);
static void InGamePlayScreen$_renderItemInHand(InGamePlayScreen* self, Player& p, bool b, float f) {
    isFirstPerson = true;
    _InGamePlayScreen$_renderItemInHand(self, p, b, f);
    isFirstPerson = false;
}

%ctor {
	Item$mItems = (Item***)(0x1012ae238 + _dyld_get_image_vmaddr_slide(0));
	Item$Tier$STONE = (Item::Tier*)(0x1012af24c + _dyld_get_image_vmaddr_slide(0));
    WeaponItem$vtable = (void**)(0x1011d8138 + _dyld_get_image_vmaddr_slide(0));
	MatrixStack::World = (MatrixStack*)(0x101267688 + _dyld_get_image_vmaddr_slide(0));

	Item$Item = (Item*(*)(Item*, std::string const&, short))(0x10074689c + _dyld_get_image_vmaddr_slide(0));
	Item$setIcon = (Item*(*)(Item*, std::string const&, int))(0x100746b0c + _dyld_get_image_vmaddr_slide(0));
	Item$setHandEquipped = (Item*(*)(Item*))(0x100746e5c + _dyld_get_image_vmaddr_slide(0));
	Item$setMaxStackSize = (Item*(*)(Item*, unsigned char))(0x100746a88 + _dyld_get_image_vmaddr_slide(0));
	Item$setMaxDamage = (Item*(*)(Item*, int))(0x10074797c + _dyld_get_image_vmaddr_slide(0));
	Item$addCreativeItem = (void(*)(ItemInstance const&))(0x100745f10 + _dyld_get_image_vmaddr_slide(0));

	PickaxeItem$PickaxeItem = (PickaxeItem*(*)(PickaxeItem*, std::string const&, int, Item::Tier const&))(0x10075f978 + _dyld_get_image_vmaddr_slide(0));

	ItemInstance$ItemInstance = (ItemInstance*(*)(ItemInstance*, int, int, int))(0x100756c70 + _dyld_get_image_vmaddr_slide(0));
	ItemInstance$getId = (int(*)(ItemInstance const*))(0x10075700c + _dyld_get_image_vmaddr_slide(0));

	MSHookFunction((void*)(0x100734d00 + _dyld_get_image_vmaddr_slide(0)), (void*)&Item$initCreativeItems, (void**)&_Item$initCreativeItems);
	MSHookFunction((void*)(0x100733348 + _dyld_get_image_vmaddr_slide(0)), (void*)&Item$registerItems, (void**)&_Item$registerItems);
	MSHookFunction((void*)(0x10074242c + _dyld_get_image_vmaddr_slide(0)), (void*)&Item$initClientData, (void**)&_Item$initClientData);

	MSHookFunction((void*)(0x10049816c + _dyld_get_image_vmaddr_slide(0)), (void*)&I18n$get, (void**)&_I18n$get);

	MSHookFunction((void*)(0x1003efcc4 + _dyld_get_image_vmaddr_slide(0)), (void*)&ItemInHandRenderer$renderItem, (void**)&_ItemInHandRenderer$renderItem);
	MSHookFunction((void*)(0x10011d1ac + _dyld_get_image_vmaddr_slide(0)), (void*)&InGamePlayScreen$_renderItemInHand, (void**)&_InGamePlayScreen$_renderItemInHand);
}