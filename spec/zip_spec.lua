-- luacheck: std min+busted
local zip = require "zip"

describe("zip", function()
   describe(".open", function()
      it("returns nil, error message on a non-existent zip file", function()
         local zfile, err = zip.open("spec/non-existent.zip")
         assert.is_nil(zfile)
         assert.is_string(err)
      end)

      it("returns a zip file object on a valid zip file", function()
         local zfile, err = zip.open("spec/luazip.zip")
         assert.is_truthy(zfile, err)
      end)
   end)

   describe(".openfile", function()
      it("returns nil, error message on a non-existent path", function()
         local file, err = zip.openfile("spec/a/b/c/e.txt")
         assert.is_nil(file)
         assert.is_string(err)
      end)

      it("returns a file object on a valid path", function()
         local file, err = zip.openfile("spec/a/b/c/d.txt")
         assert.is_truthy(file, err)
      end)

      it("accepts extension as a string", function()
         local file, err = zip.openfile("spec/a2/b2/c2/d2.txt", "ext2")
         assert.is_truthy(file, err)
         file, err = zip.openfile("spec/a2/b2/c2/e2.txt", "ext2")
         assert.is_nil(file)
         assert.is_string(err)
      end)

      it("accepts extensions as an array", function()
         local file, err = zip.openfile("spec/a3/b3/c3/d3.txt", {"ext2", "ext3"})
         assert.is_truthy(file, err)
         file, err = zip.openfile("spec/a3/b3/c3/e3.txt", {"ext2", "ext3"})
         assert.is_nil(file)
         assert.is_string(err)
      end)
   end)
end)

describe("zip file object", function()
   local zfile

   before_each(function()
      local err
      zfile, err = zip.open("spec/luazip.zip")
      assert.is_truthy(zfile, err)
   end)

   after_each(function()
      if zfile then
         zfile:close()
      end
   end)

   describe(":files", function()
      it("iterates over archived files", function()
         local names = {}

         for file in zfile:files() do
            table.insert(names, file.filename)
         end

         table.sort(names)
         assert.is_same({
            "Makefile",
            "README",
            "luazip.c",
            "luazip.h"
         }, names)
      end)
   end)

   describe(":open", function()
      it("returns nil, error message on a missing file", function()
         local file, err = zfile:open("missing.txt")
         assert.is_nil(file)
         assert.is_string(err)
      end)

      it("returns a file object on an archived file", function()
         local file, err = zfile:open("luazip.h")
         assert.is_truthy(file, err)
         -- FIXME: removing this causes a segfault.
         -- Reproduced by opening a zip file, opening a file inside it,
         -- attempting to close the zip file, closing the inner file,
         -- attempting to close the zip file again.
         file:close()
      end)
   end)

   describe(":close", function()
      it("returns true on success", function()
         local ok = zfile:close()
         assert.is_true(ok)
         zfile = nil
      end)
   end)
end)

describe("file object", function()
   local file

   before_each(function()
      local zfile, err = zip.open("spec/luazip.zip")
      assert.is_truthy(zfile, err)
      file, err = zfile:open("README")
      assert.is_truthy(file, err)
   end)

   after_each(function()
      if file then
         file:close()
      end
   end)

   describe(":read", function()
      it("reads given number of bytes", function()
         local str = file:read(2)
         assert.is_equal("\r\n", str)
         str = file:read(3)
         assert.is_equal("Lua", str)
      end)

      it("returns nil on EOF", function()
         file:read(1000)
         local str = file:read(1)
         assert.is_nil(str)
      end)
   end)

   describe(":close", function()
      it("returns true on success", function()
         local ok = file:close()
         assert.is_true(ok)
         file = nil
      end)
   end)
end)
