#
#
#

Ohai.plugin do
  provides "this"
  provides "plugin"

  depends "it/also", "depends"

  provides "provides", "a/lot", "of"

  depends "on/a"
  depends "lot", "of"
  depends "other/attributes"

  provides "attributes"
end
