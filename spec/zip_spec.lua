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
      it("throws an error on invalid mode", function()
         assert.has_error(function() file:read("*x") end, "bad argument #1 to 'read' (invalid format)")
      end)

      it("reads whole file", function()
         local str = file:read("*a")
         assert.is_equal(([[

LuaZip is a lightweight Lua extension library used to read files stored inside zip files.
Please see docs at doc/index.html or http://luazip.luaforge.net/
]]):gsub("\n", "\r\n"), str)
      end)

      it("reads lines", function()
         local str = file:read("*l")
         assert.is_equal("\r", str)
         str = file:read("*l")
         assert.is_equal("LuaZip is a lightweight Lua extension library used to read files stored inside zip files.\r", str)
      end)

      it("reads lines by default", function()
         local str = file:read()
         assert.is_equal("\r", str)
         str = file:read()
         assert.is_equal("LuaZip is a lightweight Lua extension library used to read files stored inside zip files.\r", str)
      end)

      it("reads given number of bytes", function()
         local str = file:read(2)
         assert.is_equal("\r\n", str)
         str = file:read(3)
         assert.is_equal("Lua", str)
      end)

      it("returns nil on EOF when reading given number of bytes", function()
         local str = file:read(1000)
         assert.is_equal(([[

LuaZip is a lightweight Lua extension library used to read files stored inside zip files.
Please see docs at doc/index.html or http://luazip.luaforge.net/
]]):gsub("\n", "\r\n"), str)
         str = file:read(1)
         assert.is_nil(str)
      end)

      pending("returns nil on EOF and empty string otherwise when reading 0 bytes", function()
         local str = file:read(0)
         assert.is_equal("", str)
         file:read(1000)
         str = file:read(0)
         assert.is_nil(str)
      end)

      it("returns nil on EOF when reading a line", function()
         file:read(1000)
         local str = file:read("*l")
         assert.is_nil(str)
         str = file:read()
         assert.is_nil(str)
      end)

      it("returns an empty string on EOF when reading whole file", function()
         file:read(1000)
         local str = file:read("*a")
         assert.is_equal("", str)
      end)

      it("accepts several modes", function()
         local str1, str2, str3 = file:read("*l", 6, "*l")
         assert.is_equal("\r", str1)
         assert.is_equal("LuaZip", str2)
         assert.is_equal(" is a lightweight Lua extension library used to read files stored inside zip files.\r", str3)
      end)
   end)

   describe(":seek", function()
      it("gets current position without changing it by default", function()
         local pos = file:seek()
         assert.is_equal(0, pos)
         file:read(5)
         pos = file:seek()
         assert.is_equal(5, pos)
      end)

      it("moves position to file start with set by default", function()
         local str1 = file:read(10)
         local pos = file:seek("set")
         assert.is_equal(0, pos)
         local str2 = file:read(10)
         assert.are_equal(str1, str2)
      end)

      it("moves position relatively to file start with set", function()
         local pos = file:seek("set", 14)
         assert.is_equal(14, pos)
         local str = file:read(11)
         assert.is_equal("lightweight", str)
      end)

      it("returns nil when new position is out of range", function()
         local pos = file:seek("set", 1000)
         assert.is_nil(pos)
      end)

      it("gets current position without changing it with cur by default", function()
         local pos = file:seek("cur")
         assert.is_equal(0, pos)
         file:read(5)
         pos = file:seek("cur")
         assert.is_equal(5, pos)
      end)

      it("moves position relatively to current position with cur", function()
         file:seek("set", 10)
         local pos = file:seek("cur", 4)
         assert.is_equal(14, pos)
         local str = file:read(11)
         assert.is_equal("lightweight", str)
         pos = file:seek()
         assert.is_equal(25, pos)
         pos = file:seek("cur", -14)
         assert.is_equal(11, pos)
      end)

      it("moves position to file end with end by default", function()
         file:seek("set", 10)
         local pos = file:seek("cur", 4)
         assert.is_equal(14, pos)
         local str = file:read(11)
         assert.is_equal("lightweight", str)
         pos = file:seek()
         assert.is_equal(25, pos)
         pos = file:seek("cur", -14)
         assert.is_equal(11, pos)
      end)

      it("moves position relatively to file with end", function()
         local pos = file:seek("end", -29)
         assert.is_equal(130, pos)
         local str = file:read("*l")
         assert.is_equal("http://luazip.luaforge.net/\r", str)
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
