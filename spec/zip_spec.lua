-- luacheck: std min+busted
local zip = require "zip"

describe("zip", function()
   it("is set as a global", function()
      assert.truthy(_G.zip)
      assert.are_same(zip, _G.zip)
   end)

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

   describe(".type", function()
      pending("returns nil on something that is not a zip file", function()
         local type_ = zip.type("foo")
         assert.is_nil(type_)
      end)

      it("returns 'zip file' on an open zip file", function()
         local zfile = zip.open("spec/luazip.zip")
         local type_ = zip.type(zfile)
         assert.is_equal("zip file", type_)
      end)

      it("returns 'closed zip file' on a closed zip file", function()
         local zfile = zip.open("spec/luazip.zip")
         zfile:close()
         local type_ = zip.type(zfile)
         assert.is_equal("closed zip file", type_)
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

   describe("__tostring", function()
      it("returns 'zip file (address) on an open file", function()
         local str = tostring(zfile)
         assert.matches("^zip file %(.+%)$", str)
      end)

      it("returns 'zip file (closed) on a closed file", function()
         zfile:close()
         local str = tostring(zfile)
         zfile = nil
         assert.is_equal("zip file (closed)", str)
      end)
   end)

   describe(":close", function()
      it("returns true on success", function()
         local ok = zfile:close()
         zfile = nil
         assert.is_true(ok)
      end)
   end)
end)

describe("file object", function()
   local function register_tests(name, get_file, clean_up)
      local file

      before_each(function()
         file = get_file()
      end)

      after_each(function()
         if file then
            file:close()
         end

         if clean_up then
            clean_up()
         end
      end)

      describe(name, function()
         describe(":read", function()
            it("throws an error on invalid mode", function()
               assert.has_error(function() file:read("*x") end, "bad argument #1 to 'read' (invalid format)")
            end)

            it("reads whole file", function()
               local str = file:read("*a")
               assert.is_equal(([[

LuaZip is a lightweight Lua extension library used to read files stored inside zip files.
Please see docs at doc/index.html or http://luazip.luaforge.net/
last line]]):gsub("\n", "\r\n"), str)
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
               str = file:read()
               assert.is_equal("Please see docs at doc/index.html or http://luazip.luaforge.net/\r", str)
               str = file:read()
               assert.is_equal("last line", str)
               str = file:read()
               assert.is_nil(str)
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
last line]]):gsub("\n", "\r\n"), str)
               str = file:read(1)
               assert.is_nil(str)
            end)

            it("returns nil on EOF and empty string otherwise when reading 0 bytes", function()
               local str = file:read(0)
               assert.is_equal("", str)
               str = file:read(2)
               assert.is_equal("\r\n", str)
               file:read(1000)
               str = file:read(0)
               assert.is_nil(str)
               str = file:read(1)
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
               local pos = file:seek("end", -38)
               assert.is_equal(130, pos)
               local str = file:read("*l")
               assert.is_equal("http://luazip.luaforge.net/\r", str)
            end)
         end)

         describe(":lines", function()
            it("returns an iterator reading lines from the file", function()
               local iter = file:lines()
               assert.is_function(iter)
               local lines = {}

               for line in iter do
                  table.insert(lines, line)
               end

               assert.is_same({
                  "\r",
                  "LuaZip is a lightweight Lua extension library used to read files stored inside zip files.\r",
                  "Please see docs at doc/index.html or http://luazip.luaforge.net/\r",
                  "last line"
               }, lines)
            end)
         end)

         describe("__tostring", function()
            it("returns 'file in zip file (address) on an open file", function()
               local str = tostring(file)
               assert.matches("^file in zip file %(.+%)$", str)
            end)

            it("returns 'file in zip file (closed) on a closed file", function()
               file:close()
               local str = tostring(file)
               file = nil
               assert.is_equal("file in zip file (closed)", str)
            end)
         end)

         describe(":close", function()
            it("returns true on success", function()
               local ok = file:close()
               file = nil
               assert.is_true(ok)
            end)
         end)
      end)
   end

   local zfile

   register_tests("(in zip archive)", function()
      local err
      zfile, err = zip.open("spec/luazip.zip")
      assert.is_truthy(zfile, err)
      local file
      file, err = zfile:open("README")
      assert.is_truthy(file, err)
      return file
   end, function()
      if zfile then
         zfile:close()
      end
   end)

   register_tests("(real)", function()
      local file, err = zip.openfile("spec/readme_sample")
      assert.is_truthy(file, err)
      return file
   end)
end)
