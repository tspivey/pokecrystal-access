describe("Trail", function()
  local trail = require("trail")
  it("should have a direction", function()
    assert.are.equal("", trail.only_direction(0, 0, 0, 0))
    assert.are.equal("up", trail.only_direction(0, 0, 0, -1))
    assert.are.equal("down", trail.only_direction(0, 0, 0, 1))
    assert.are.equal("left", trail.only_direction(0, 0, -1, 0))
    assert.are.equal("right", trail.only_direction(0, 0, 1, 0))
  end)
  it("should have a path", function()
    assert.are.equal("", trail.direction(0, 0, 0, 0))
    assert.are.equal("1 up", trail.direction(0, 0, 0, -1))
    assert.are.equal("1 down", trail.direction(0, 0, 0, 1))
    assert.are.equal(" 1 left", trail.direction(0, 0, -1, 0))
    assert.are.equal(" 1 right", trail.direction(0, 0, 1, 0))
  end)
end)
