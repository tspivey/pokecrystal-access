describe("Guide", function()
  local guide = require("guide")
  it("should find a path", function()
    zero = {{7, 7, 7}, {7, 7, 7}, {7, 7, 7}}
    assert.are.same({{type = 7, x = 1, y = 1}}, guide.find_path_to({x = 1, y = 1}, #zero, #zero[1], 1, 1, zero, {}, {}, {}, {[7] = true}))
  end)
end)
