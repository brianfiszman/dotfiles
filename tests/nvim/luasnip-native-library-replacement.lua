package.path = vim.fn.getcwd() .. "/.config/nvim/lua/?.lua;" .. package.path

local root = assert(vim.env.DOTFILES_LUASNIP_REPLACEMENT_TEST_DIR,
  "DOTFILES_LUASNIP_REPLACEMENT_TEST_DIR is required")
local marker = root .. "/finalizer.txt"
vim.env.DOTFILES_LUASNIP_FINALIZER_MARKER = marker

local function write(path, contents)
  assert(vim.fn.writefile(vim.split(contents, "\n"), path) == 0,
    "could not write test source: " .. path)
end

local original_source = [[
#include <stdio.h>
#include <stdlib.h>
__attribute__((destructor)) static void original_finalizer(void) {
  const char *path = getenv("DOTFILES_LUASNIP_FINALIZER_MARKER");
  if (path) {
    FILE *stream = fopen(path, "w");
    if (stream) { fputs("original", stream); fclose(stream); }
  }
}
int luaopen_dotfiles_test(void) { return 0; }
int dotfiles_original(void) { return 1; }
]]

local replacement_source = [[
#include <stdio.h>
#include <stdlib.h>
__attribute__((destructor)) static void replacement_finalizer(void) {
  const char *path = getenv("DOTFILES_LUASNIP_FINALIZER_MARKER");
  if (path) {
    FILE *stream = fopen(path, "w");
    if (stream) { fputs("replacement", stream); fclose(stream); }
  }
}
int luaopen_dotfiles_test(void) { return 0; }
int dotfiles_replacement(void) { return 2; }
]]

local original_c = root .. "/original.c"
local replacement_c = root .. "/replacement.c"
local original_so = root .. "/original.so"
local replacement_so = root .. "/replacement.so"
local loaded_so = root .. "/loaded.so"
write(original_c, original_source)
write(replacement_c, replacement_source)

local compiler = vim.env.CC or "cc"
local function compile(source, output)
  local result = vim.system({
    compiler, "-shared", "-fPIC", "-O2", "-o", output, source,
  }, { text = true }):wait()
  assert(result.code == 0,
    ("compiler failed (%s):\n%s\n%s"):format(
      tostring(result.code), result.stdout or "", result.stderr or ""
    ))
end

compile(original_c, original_so)
compile(replacement_c, replacement_so)
local copied, copy_error = vim.uv.fs_copyfile(original_so, loaded_so)
assert(copied, "could not seed loaded library: " .. tostring(copy_error))

local loader, load_error = package.loadlib(loaded_so, "luaopen_dotfiles_test")
assert(loader, "could not dlopen original library: " .. tostring(load_error))
_G.dotfiles_luasnip_native_library_loader = loader
loader()

require("snippets.luasnip_build").replace_file_atomically(replacement_so, loaded_so)
print("PASS: replacing a loaded native library preserves its original finalizer")
vim.cmd("qa!")
