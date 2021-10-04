CC = gcc
CFLAGS = -Wall

SRCDIR = src
SRCFILES = $(shell find src -name "*.c")
BUILDDIR = build

OBJDIR = $(BUILDDIR)/obj
OBJFILES = $(patsubst $(SRCDIR)/%.c, $(OBJDIR)/%.o, $(SRCFILES))
OBJFLAGS = -fPIC

LINKFLAGS = -shared

.PHONY: clean
	
erdec: $(OBJFILES)
	$(CC) $(CFLAGS) $(LINKFLAGS) $(OBJFILES) -o $(BUILDDIR)/$@.so

$(BUILDDIR)/obj/%.o: $(SRCDIR)/%.c
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) $(OBJFLAGS) -c $< -o $@

clean:
	@rm -r $(BUILDDIR)
