param(
  [int[]]$Sizes = @(192,512)
)

# Generates calculator icons using System.Drawing (Windows built-in)
# Output: icon-192.png, icon-512.png in current folder

Add-Type -AssemblyName System.Drawing
# Note: System.Drawing.Drawing2D types are in System.Drawing; no separate Add-Type is required.

function New-Brush([string]$hex){
  $hex = $hex.TrimStart('#')
  [System.Drawing.Color]::FromArgb(
    [Convert]::ToInt32($hex.Substring(0,2),16),
    [Convert]::ToInt32($hex.Substring(2,2),16),
    [Convert]::ToInt32($hex.Substring(4,2),16)
  )
}

function New-Color([string]$hex){
  $hex = $hex.TrimStart('#')
  if($hex.Length -eq 6){ return [System.Drawing.ColorTranslator]::FromHtml('#'+$hex) }
  elseif($hex.Length -eq 8){
    $a=[Convert]::ToInt32($hex.Substring(0,2),16)
    $r=[Convert]::ToInt32($hex.Substring(2,2),16)
    $g=[Convert]::ToInt32($hex.Substring(4,2),16)
    $b=[Convert]::ToInt32($hex.Substring(6,2),16)
    return [System.Drawing.Color]::FromArgb($a,$r,$g,$b)
  }
  else { return [System.Drawing.Color]::Black }
}

function DrawRoundedRect([System.Drawing.Graphics]$g, [System.Drawing.RectangleF]$rect, [float]$radius, [System.Drawing.Brush]$fill, [System.Drawing.Pen]$pen){
  $gp = New-Object System.Drawing.Drawing2D.GraphicsPath
  $d = $radius*2
  $gp.AddArc($rect.X, $rect.Y, $d, $d, 180, 90)
  $gp.AddArc($rect.Right-$d, $rect.Y, $d, $d, 270, 90)
  $gp.AddArc($rect.Right-$d, $rect.Bottom-$d, $d, $d, 0, 90)
  $gp.AddArc($rect.X, $rect.Bottom-$d, $d, $d, 90, 90)
  $gp.CloseFigure()
  if($fill){ $g.FillPath($fill, $gp) }
  if($pen){ $g.DrawPath($pen, $gp) }
  $gp.Dispose()
}

function Make-Icon([int]$size, [string]$outPath){
  $bmp = New-Object System.Drawing.Bitmap($size,$size)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
  $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

  # Background gradient
  $bgRect = New-Object -TypeName System.Drawing.RectangleF -ArgumentList ([single]0),([single]0),([single]$size),([single]$size)
  $bgBrush = New-Object -TypeName System.Drawing.Drawing2D.LinearGradientBrush -ArgumentList $bgRect,(New-Color '#0f1222'),(New-Color '#171a2b'),90
  $g.FillRectangle($bgBrush, $bgRect)
  $bgBrush.Dispose()

  # Calculator body
  $pad = [math]::Round($size*0.10)
  $body = New-Object -TypeName System.Drawing.RectangleF -ArgumentList ([single]$pad),([single]$pad),([single]($size-2*$pad)),([single]($size-2*$pad))
  $bodyBrush = New-Object -TypeName System.Drawing.SolidBrush -ArgumentList (New-Color '#171a2b')
  $bodyPen = New-Object -TypeName System.Drawing.Pen -ArgumentList (New-Color '#2b2f4a'), ([single]([math]::Max(1, $size*0.01)))
  DrawRoundedRect $g $body ($size*0.08) $bodyBrush $bodyPen
  $bodyBrush.Dispose(); $bodyPen.Dispose()

  # Display area
  $dispH = [math]::Round($body.Height*0.18)
  $dispRect = New-Object -TypeName System.Drawing.RectangleF -ArgumentList ([single]($body.X + $size*0.06)), ([single]($body.Y + $size*0.06)), ([single]($body.Width - $size*0.12)), ([single]$dispH)
  $dispBrush = New-Object -TypeName System.Drawing.SolidBrush -ArgumentList (New-Color '#1f2340')
  $dispPen = New-Object -TypeName System.Drawing.Pen -ArgumentList (New-Color '#252a4a'), ([single]([math]::Max(1, $size*0.006)))
  DrawRoundedRect $g $dispRect ($size*0.03) $dispBrush $dispPen
  $dispBrush.Dispose(); $dispPen.Dispose()

  # Buttons grid 4x4
  $cols = 4; $rows = 4
  $gap = $size*0.02
  $gridTop = $dispRect.Bottom + $size*0.05
  $gridLeft = $dispRect.X
  $gridW = $dispRect.Width
  $gridH = $body.Bottom - $gridTop - $size*0.06
  $btnW = ($gridW - $gap*($cols-1)) / $cols
  $btnH = ($gridH - $gap*($rows-1)) / $rows

  $btnBrush = New-Object -TypeName System.Drawing.SolidBrush -ArgumentList (New-Color '#22ffffff') # light with alpha
  $btnPen = New-Object -TypeName System.Drawing.Pen -ArgumentList (New-Color '#33ffffff'), ([single]([math]::Max(1,$size*0.004)))
  $eqBrush = New-Object -TypeName System.Drawing.SolidBrush -ArgumentList (New-Color '#6ea8ff')
  $eqPen = New-Object -TypeName System.Drawing.Pen -ArgumentList (New-Color '#90bfff'), ([single]([math]::Max(1,$size*0.004)))

  for($r=0; $r -lt $rows; $r++){
    for($c=0; $c -lt $cols; $c++){
      $x = $gridLeft + $c*($btnW + $gap)
      $y = $gridTop + $r*($btnH + $gap)
      $rect = New-Object -TypeName System.Drawing.RectangleF -ArgumentList ([single]$x),([single]$y),([single]$btnW),([single]$btnH)
      $radius = $size*0.03
      $isEq = ($r -eq ($rows-1) -and $c -eq ($cols-1))
      if($isEq){
        DrawRoundedRect $g $rect $radius $eqBrush $eqPen
      } else {
        DrawRoundedRect $g $rect $radius $btnBrush $btnPen
      }
    }
  }
  $btnBrush.Dispose(); $btnPen.Dispose(); $eqBrush.Dispose(); $eqPen.Dispose()

  # Optional: draw '=' using two lines to avoid Font dependency
  $eqPen2 = New-Object -TypeName System.Drawing.Pen -ArgumentList (New-Color '#a8b0c2'), ([single]([math]::Max(1, $size*0.012)))
  $xL = [single]($dispRect.Right - $dispRect.Width*0.35)
  $xR = [single]($dispRect.Right - $dispRect.Width*0.10)
  $y1 = [single]($dispRect.Y + $dispRect.Height*0.42)
  $y2 = [single]($dispRect.Y + $dispRect.Height*0.60)
  $g.DrawLine($eqPen2, $xL, $y1, $xR, $y1)
  $g.DrawLine($eqPen2, $xL, $y2, $xR, $y2)
  $eqPen2.Dispose()

  # Save
  $bmp.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
  $g.Dispose(); $bmp.Dispose()
}

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
foreach($sz in $Sizes){
  $out = Join-Path $here ("icon-$sz.png")
  Write-Host "Generating $out"
  Make-Icon -size $sz -outPath $out
}

Write-Host 'Done.'
