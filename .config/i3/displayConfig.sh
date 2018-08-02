if xrandr | grep -q 'HDMI1 connected' ; then
    xrandr --output LVDS1 --off
    xrandr --output HDMI1 --auto --right-of LVDS1
    xrandr --output HDMI1 --primary
fi
