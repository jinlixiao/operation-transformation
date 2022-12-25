defmodule TransformTest do
  use ExUnit.Case
  doctest OT

  import Kernel,
    except: [spawn: 3, spawn: 1, spawn_link: 1, spawn_link: 3, send: 2]

  test "transform ins with ins" do
    op0 = OP.new(%{a: -1}, :a, :insert, "a", 0)
    op1 = OP.new(%{a: -2}, :a, :insert, "b", 1)
    op2 = OP.new(%{a: -3}, :a, :insert, "c", 2)
    op3 = OP.new(%{a: -4}, :a, :insert, "d", 3)
    op4 = OP.new(%{a: -5}, :a, :insert, "e", 4)
    op5 = OP.new(%{a: -6}, :a, :insert, "f", 5)
    op6 = OP.new(%{a: -7}, :a, :insert, "g", 6)
    op7 = OP.new(%{a: -8}, :a, :insert, "h", 7)
    op8 = OP.new(%{a: -9}, :a, :insert, "i", 8)

    ops = [
      OP.new(%{a: 1}, :a, :insert, "a", 0),
      OP.new(%{a: 2}, :a, :insert, "b", 0),
      OP.new(%{a: 3}, :a, :insert, "c", 0),
      OP.new(%{a: 4}, :a, :insert, "d", 3),
      OP.new(%{a: 5}, :a, :insert, "e", 1),
      OP.new(%{a: 6}, :a, :insert, "f", 0),
      OP.new(%{a: 7}, :a, :insert, "g", 3),
      OP.new(%{a: 8}, :a, :insert, "h", 0),
      OP.new(%{a: 9}, :a, :insert, "i", 5),
      OP.new(%{a: 10}, :a, :insert, "j", 0),
      OP.new(%{a: 11}, :a, :insert, "k", 2),
      OP.new(%{a: 12}, :a, :insert, "l", 3),
      OP.new(%{a: 13}, :a, :insert, "m", 3),
      OP.new(%{a: 14}, :a, :insert, "n", 3),
      OP.new(%{a: 15}, :a, :insert, "a", 0),
      OP.new(%{a: 16}, :a, :insert, "b", 0),
      OP.new(%{a: 17}, :a, :insert, "c", 0),
      OP.new(%{a: 18}, :a, :insert, "d", 3),
      OP.new(%{a: 19}, :a, :insert, "e", 1),
      OP.new(%{a: 20}, :a, :insert, "f", 0),
      OP.new(%{a: 21}, :a, :insert, "g", 3),
      OP.new(%{a: 22}, :a, :insert, "h", 0),
      OP.new(%{a: 23}, :a, :insert, "i", 5),
      OP.new(%{a: 24}, :a, :insert, "j", 0),
      OP.new(%{a: 25}, :a, :insert, "k", 2),
      OP.new(%{a: 26}, :a, :insert, "l", 3),
      OP.new(%{a: 27}, :a, :insert, "m", 3),
      OP.new(%{a: 28}, :a, :insert, "n", 3)
    ]

    assert Transform.list_et(Transform.list_it(op0, ops), Enum.reverse(ops)) == op0
    assert Transform.list_et(Transform.list_it(op1, ops), Enum.reverse(ops)) == op1
    assert Transform.list_et(Transform.list_it(op2, ops), Enum.reverse(ops)) == op2
    assert Transform.list_et(Transform.list_it(op3, ops), Enum.reverse(ops)) == op3
    assert Transform.list_et(Transform.list_it(op4, ops), Enum.reverse(ops)) == op4
    assert Transform.list_et(Transform.list_it(op5, ops), Enum.reverse(ops)) == op5
    assert Transform.list_et(Transform.list_it(op6, ops), Enum.reverse(ops)) == op6
    assert Transform.list_et(Transform.list_it(op7, ops), Enum.reverse(ops)) == op7
    assert Transform.list_et(Transform.list_it(op8, ops), Enum.reverse(ops)) == op8

    assert Transform.list_it(Transform.list_et(op0, ops), Enum.reverse(ops)) == op0
    assert Transform.list_it(Transform.list_et(op1, ops), Enum.reverse(ops)) == op1
    assert Transform.list_it(Transform.list_et(op2, ops), Enum.reverse(ops)) == op2
    assert Transform.list_it(Transform.list_et(op3, ops), Enum.reverse(ops)) == op3
    assert Transform.list_it(Transform.list_et(op4, ops), Enum.reverse(ops)) == op4
    assert Transform.list_it(Transform.list_et(op5, ops), Enum.reverse(ops)) == op5
    assert Transform.list_it(Transform.list_et(op6, ops), Enum.reverse(ops)) == op6
    assert Transform.list_it(Transform.list_et(op7, ops), Enum.reverse(ops)) == op7
    assert Transform.list_it(Transform.list_et(op8, ops), Enum.reverse(ops)) == op8
  end

  test "transform ins with del" do
    op0 = OP.new(%{a: -1}, :a, :insert, "a", 0)
    op1 = OP.new(%{a: -2}, :a, :insert, "b", 1)
    op2 = OP.new(%{a: -3}, :a, :insert, "c", 2)
    op3 = OP.new(%{a: -4}, :a, :insert, "d", 3)
    op4 = OP.new(%{a: -5}, :a, :insert, "e", 4)
    op5 = OP.new(%{a: -6}, :a, :insert, "f", 5)
    op6 = OP.new(%{a: -7}, :a, :insert, "g", 6)
    op7 = OP.new(%{a: -8}, :a, :insert, "h", 7)
    op8 = OP.new(%{a: -9}, :a, :insert, "i", 8)

    ops = [
      OP.new(%{a: 1}, :a, :delete, "a", 0),
      OP.new(%{a: 2}, :a, :delete, "b", 0),
      OP.new(%{a: 3}, :a, :delete, "c", 0),
      OP.new(%{a: 4}, :a, :delete, "d", 3),
      OP.new(%{a: 5}, :a, :delete, "e", 1),
      OP.new(%{a: 6}, :a, :delete, "f", 0),
      OP.new(%{a: 7}, :a, :delete, "g", 3),
      OP.new(%{a: 8}, :a, :delete, "h", 0),
      OP.new(%{a: 9}, :a, :delete, "i", 5),
      OP.new(%{a: 10}, :a, :delete, "j", 0),
      OP.new(%{a: 11}, :a, :delete, "k", 2),
      OP.new(%{a: 12}, :a, :delete, "l", 3),
      OP.new(%{a: 13}, :a, :delete, "m", 3),
      OP.new(%{a: 14}, :a, :delete, "n", 3),
      OP.new(%{a: 15}, :a, :delete, "a", 0),
      OP.new(%{a: 16}, :a, :delete, "b", 0),
      OP.new(%{a: 17}, :a, :delete, "c", 0),
      OP.new(%{a: 18}, :a, :delete, "d", 3),
      OP.new(%{a: 19}, :a, :delete, "e", 1),
      OP.new(%{a: 20}, :a, :delete, "f", 0),
      OP.new(%{a: 21}, :a, :delete, "g", 3),
      OP.new(%{a: 22}, :a, :delete, "h", 0),
      OP.new(%{a: 23}, :a, :delete, "i", 5),
      OP.new(%{a: 24}, :a, :delete, "j", 0),
      OP.new(%{a: 25}, :a, :delete, "k", 2),
      OP.new(%{a: 26}, :a, :delete, "l", 3),
      OP.new(%{a: 27}, :a, :delete, "m", 3),
      OP.new(%{a: 28}, :a, :delete, "n", 3)
    ]

    assert Transform.list_et(Transform.list_it(op0, ops), Enum.reverse(ops)) == op0
    assert Transform.list_et(Transform.list_it(op1, ops), Enum.reverse(ops)) == op1
    assert Transform.list_et(Transform.list_it(op2, ops), Enum.reverse(ops)) == op2
    assert Transform.list_et(Transform.list_it(op3, ops), Enum.reverse(ops)) == op3
    assert Transform.list_et(Transform.list_it(op4, ops), Enum.reverse(ops)) == op4
    assert Transform.list_et(Transform.list_it(op5, ops), Enum.reverse(ops)) == op5
    assert Transform.list_et(Transform.list_it(op6, ops), Enum.reverse(ops)) == op6
    assert Transform.list_et(Transform.list_it(op7, ops), Enum.reverse(ops)) == op7
    assert Transform.list_et(Transform.list_it(op8, ops), Enum.reverse(ops)) == op8

    assert Transform.list_it(Transform.list_et(op0, ops), Enum.reverse(ops)) == op0
    assert Transform.list_it(Transform.list_et(op1, ops), Enum.reverse(ops)) == op1
    assert Transform.list_it(Transform.list_et(op2, ops), Enum.reverse(ops)) == op2
    assert Transform.list_it(Transform.list_et(op3, ops), Enum.reverse(ops)) == op3
    assert Transform.list_it(Transform.list_et(op4, ops), Enum.reverse(ops)) == op4
    assert Transform.list_it(Transform.list_et(op5, ops), Enum.reverse(ops)) == op5
    assert Transform.list_it(Transform.list_et(op6, ops), Enum.reverse(ops)) == op6
    assert Transform.list_it(Transform.list_et(op7, ops), Enum.reverse(ops)) == op7
    assert Transform.list_it(Transform.list_et(op8, ops), Enum.reverse(ops)) == op8
  end

  test "transform del with ins" do
    op0 = OP.new(%{a: -1}, :a, :delete, "a", 0)
    op1 = OP.new(%{a: -2}, :a, :delete, "b", 1)
    op2 = OP.new(%{a: -3}, :a, :delete, "c", 2)
    op3 = OP.new(%{a: -4}, :a, :delete, "d", 3)
    op4 = OP.new(%{a: -5}, :a, :delete, "e", 4)
    op5 = OP.new(%{a: -6}, :a, :delete, "f", 5)
    op6 = OP.new(%{a: -7}, :a, :delete, "g", 6)
    op7 = OP.new(%{a: -8}, :a, :delete, "h", 7)
    op8 = OP.new(%{a: -9}, :a, :delete, "i", 8)

    ops = [
      OP.new(%{a: 1}, :a, :insert, "a", 0),
      OP.new(%{a: 2}, :a, :insert, "b", 0),
      OP.new(%{a: 3}, :a, :insert, "c", 0),
      OP.new(%{a: 4}, :a, :insert, "d", 3),
      OP.new(%{a: 5}, :a, :insert, "e", 1),
      OP.new(%{a: 6}, :a, :insert, "f", 0),
      OP.new(%{a: 7}, :a, :insert, "g", 3),
      OP.new(%{a: 8}, :a, :insert, "h", 0),
      OP.new(%{a: 9}, :a, :insert, "i", 5),
      OP.new(%{a: 10}, :a, :insert, "j", 0),
      OP.new(%{a: 11}, :a, :insert, "k", 2),
      OP.new(%{a: 12}, :a, :insert, "l", 3),
      OP.new(%{a: 13}, :a, :insert, "m", 3),
      OP.new(%{a: 14}, :a, :insert, "n", 3),
      OP.new(%{a: 15}, :a, :insert, "a", 0),
      OP.new(%{a: 16}, :a, :insert, "b", 0),
      OP.new(%{a: 17}, :a, :insert, "c", 0),
      OP.new(%{a: 18}, :a, :insert, "d", 3),
      OP.new(%{a: 19}, :a, :insert, "e", 1),
      OP.new(%{a: 20}, :a, :insert, "f", 0),
      OP.new(%{a: 21}, :a, :insert, "g", 3),
      OP.new(%{a: 22}, :a, :insert, "h", 0),
      OP.new(%{a: 23}, :a, :insert, "i", 5),
      OP.new(%{a: 24}, :a, :insert, "j", 0),
      OP.new(%{a: 25}, :a, :insert, "k", 2),
      OP.new(%{a: 26}, :a, :insert, "l", 3),
      OP.new(%{a: 27}, :a, :insert, "m", 3),
      OP.new(%{a: 28}, :a, :insert, "n", 3)
    ]

    assert Transform.list_et(Transform.list_it(op0, ops), Enum.reverse(ops)) == op0
    assert Transform.list_et(Transform.list_it(op1, ops), Enum.reverse(ops)) == op1
    assert Transform.list_et(Transform.list_it(op2, ops), Enum.reverse(ops)) == op2
    assert Transform.list_et(Transform.list_it(op3, ops), Enum.reverse(ops)) == op3
    assert Transform.list_et(Transform.list_it(op4, ops), Enum.reverse(ops)) == op4
    assert Transform.list_et(Transform.list_it(op5, ops), Enum.reverse(ops)) == op5
    assert Transform.list_et(Transform.list_it(op6, ops), Enum.reverse(ops)) == op6
    assert Transform.list_et(Transform.list_it(op7, ops), Enum.reverse(ops)) == op7
    assert Transform.list_et(Transform.list_it(op8, ops), Enum.reverse(ops)) == op8

    assert Transform.list_it(Transform.list_et(op0, ops), Enum.reverse(ops)) == op0
    assert Transform.list_it(Transform.list_et(op1, ops), Enum.reverse(ops)) == op1
    assert Transform.list_it(Transform.list_et(op2, ops), Enum.reverse(ops)) == op2
    assert Transform.list_it(Transform.list_et(op3, ops), Enum.reverse(ops)) == op3
    assert Transform.list_it(Transform.list_et(op4, ops), Enum.reverse(ops)) == op4
    assert Transform.list_it(Transform.list_et(op5, ops), Enum.reverse(ops)) == op5
    assert Transform.list_it(Transform.list_et(op6, ops), Enum.reverse(ops)) == op6
    assert Transform.list_it(Transform.list_et(op7, ops), Enum.reverse(ops)) == op7
    assert Transform.list_it(Transform.list_et(op8, ops), Enum.reverse(ops)) == op8
  end

  test "transform del with del" do
    op0 = OP.new(%{a: -1}, :a, :delete, "a", 0)
    op1 = OP.new(%{a: -2}, :a, :delete, "b", 1)
    op2 = OP.new(%{a: -3}, :a, :delete, "c", 2)
    op3 = OP.new(%{a: -4}, :a, :delete, "d", 3)
    op4 = OP.new(%{a: -5}, :a, :delete, "e", 4)
    op5 = OP.new(%{a: -6}, :a, :delete, "f", 5)
    op6 = OP.new(%{a: -7}, :a, :delete, "g", 6)
    op7 = OP.new(%{a: -8}, :a, :delete, "h", 7)
    op8 = OP.new(%{a: -9}, :a, :delete, "i", 8)

    ops = [
      OP.new(%{a: 1}, :a, :delete, "a", 0),
      OP.new(%{a: 2}, :a, :delete, "b", 0),
      OP.new(%{a: 3}, :a, :delete, "c", 0),
      OP.new(%{a: 4}, :a, :delete, "d", 3),
      OP.new(%{a: 5}, :a, :delete, "e", 1),
      OP.new(%{a: 6}, :a, :delete, "f", 0),
      OP.new(%{a: 7}, :a, :delete, "g", 3),
      OP.new(%{a: 8}, :a, :delete, "h", 0),
      OP.new(%{a: 9}, :a, :delete, "i", 5),
      OP.new(%{a: 10}, :a, :delete, "j", 0),
      OP.new(%{a: 11}, :a, :delete, "k", 2),
      OP.new(%{a: 12}, :a, :delete, "l", 3),
      OP.new(%{a: 13}, :a, :delete, "m", 3),
      OP.new(%{a: 14}, :a, :delete, "n", 3),
      OP.new(%{a: 15}, :a, :delete, "a", 0),
      OP.new(%{a: 16}, :a, :delete, "b", 0),
      OP.new(%{a: 17}, :a, :delete, "c", 0),
      OP.new(%{a: 18}, :a, :delete, "d", 3),
      OP.new(%{a: 19}, :a, :delete, "e", 1),
      OP.new(%{a: 20}, :a, :delete, "f", 0),
      OP.new(%{a: 21}, :a, :delete, "g", 3),
      OP.new(%{a: 22}, :a, :delete, "h", 0),
      OP.new(%{a: 23}, :a, :delete, "i", 5),
      OP.new(%{a: 24}, :a, :delete, "j", 0),
      OP.new(%{a: 25}, :a, :delete, "k", 2),
      OP.new(%{a: 26}, :a, :delete, "l", 3),
      OP.new(%{a: 27}, :a, :delete, "m", 3),
      OP.new(%{a: 28}, :a, :delete, "n", 3)
    ]

    assert Transform.list_et(Transform.list_it(op1, ops), Enum.reverse(ops)) == op1
    assert Transform.list_et(Transform.list_it(op2, ops), Enum.reverse(ops)) == op2
    assert Transform.list_et(Transform.list_it(op3, ops), Enum.reverse(ops)) == op3
    assert Transform.list_et(Transform.list_it(op4, ops), Enum.reverse(ops)) == op4
    assert Transform.list_et(Transform.list_it(op5, ops), Enum.reverse(ops)) == op5
    assert Transform.list_et(Transform.list_it(op6, ops), Enum.reverse(ops)) == op6
    assert Transform.list_et(Transform.list_it(op7, ops), Enum.reverse(ops)) == op7
    assert Transform.list_et(Transform.list_it(op8, ops), Enum.reverse(ops)) == op8

    assert Transform.list_it(Transform.list_et(op0, ops), Enum.reverse(ops)) == op0
    assert Transform.list_it(Transform.list_et(op1, ops), Enum.reverse(ops)) == op1
    assert Transform.list_it(Transform.list_et(op2, ops), Enum.reverse(ops)) == op2
    assert Transform.list_it(Transform.list_et(op3, ops), Enum.reverse(ops)) == op3
    assert Transform.list_it(Transform.list_et(op4, ops), Enum.reverse(ops)) == op4
    assert Transform.list_it(Transform.list_et(op5, ops), Enum.reverse(ops)) == op5
    assert Transform.list_it(Transform.list_et(op6, ops), Enum.reverse(ops)) == op6
    assert Transform.list_it(Transform.list_et(op7, ops), Enum.reverse(ops)) == op7
    assert Transform.list_it(Transform.list_et(op8, ops), Enum.reverse(ops)) == op8
  end
end
