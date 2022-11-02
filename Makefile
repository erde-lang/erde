LUA_TARGET_TAGS_JIT := "jit,5.1%+"
LUA_TARGET_TAGS_5.1+ := "5.1%+"
LUA_TARGET_TAGS_5.1 := "5.1,$(LUA_TARGET_TAGS_5.1+)"
LUA_TARGET_TAGS_5.2+ := "5.2%+,$(LUA_TARGET_TAGS_5.1+)"
LUA_TARGET_TAGS_5.2 := "5.2,$(LUA_TARGET_TAGS_5.2+)"
LUA_TARGET_TAGS_5.3+ := "5.3%+,$(LUA_TARGET_TAGS_5.2+)"
LUA_TARGET_TAGS_5.3 := "5.3,$(LUA_TARGET_TAGS_5.3+)"
LUA_TARGET_TAGS_5.4+ := "5.4%+,$(LUA_TARGET_TAGS_5.3+)"
LUA_TARGET_TAGS_5.4 := "5.4,$(LUA_TARGET_TAGS_5.4+)"

.PHONY: test

define runtest
	$(eval LUA_EXECUTABLE = $(1))
	$(eval LUA_TARGET = $(2))
	$(eval LUA_TARGET_TAGS = $(LUA_TARGET_TAGS_$(shell echo $(LUA_TARGET) | tr a-z A-Z)))
  @echo "targeting $(LUA_TARGET) on $(LUA_EXECUTABLE)"
  @LUA_TARGET="$(LUA_TARGET)" busted --lua="/usr/bin/$(LUA_EXECUTABLE)" --tags="$(LUA_TARGET_TAGS)"
  @echo
endef

test:
	@echo
	$(call runtest,luajit,jit)
	$(call runtest,luajit,5.1+)
	$(call runtest,lua5.1,5.1)
	$(call runtest,lua5.1,5.1+)
	$(call runtest,lua5.2,5.2)
	$(call runtest,lua5.2,5.1+)
	$(call runtest,lua5.2,5.2+)
	$(call runtest,lua5.3,5.3)
	$(call runtest,lua5.3,5.1+)
	$(call runtest,lua5.3,5.2+)
	$(call runtest,lua5.3,5.3+)
	$(call runtest,lua5.4,5.4)
	$(call runtest,lua5.4,5.1+)
	$(call runtest,lua5.4,5.2+)
	$(call runtest,lua5.4,5.3+)
	$(call runtest,lua5.4,5.4+)
