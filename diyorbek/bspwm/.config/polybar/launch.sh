killall -q polybar

polybar mybar 2>&1 | tee -a /temp/polybar.log & disown

echo "Polybar launched..."
