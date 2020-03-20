object frm: Tfrm
  Left = -7
  Top = 0
  AlphaBlend = True
  AlphaBlendValue = 0
  Anchors = []
  BorderIcons = []
  BorderStyle = bsNone
  ClientHeight = 240
  ClientWidth = 120
  Color = clWhite
  TransparentColor = True
  TransparentColorValue = clWhite
  Constraints.MaxHeight = 240
  Constraints.MaxWidth = 136
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  PixelsPerInch = 96
  TextHeight = 13
  object tim: TTimer
    Interval = 50
    OnTimer = timTimer
    Left = 8
    Top = 8
  end
end
