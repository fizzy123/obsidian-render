set -e
. /root/.bashrc

# setup
cd /root/obsidianHosting
rm -rf obsidian_nobel
rm -rf _obsidian_nobel
rm -rf mk.zip
rm -rf /var/www

# download
DROPBOX_ACCESS_TOKEN=$(curl -s https://api.dropbox.com/oauth2/token -d grant_type=refresh_token -d refresh_token=$DROPBOX_REFRESH_TOKEN -u $DROPBOX_APP_KEY:$DROPBOX_APP_SECRET | jq -r '.access_token')
curl -s -X POST https://content.dropboxapi.com/2/files/download_zip \
  --header "Authorization: Bearer $DROPBOX_ACCESS_TOKEN" \
  --header "Dropbox-API-Arg: {\"path\":\"/obsidian_nobel\"}" > mk.zip
unzip mk.zip

# Remove notes I don't want to publish
rm -rf obsidian_nobel/Personal
rm -rf obsidian_nobel/Unorganized_Thoughts.md

cd /root/obsidianHosting/obsidian_nobel/03_Blog/
for file in *
do
  # Add title to top of Markdown
  echo "$file" | cut -d "." -f 1 | awk '{print "# "$1"\n"}' | tr _ " " | cat - "$file" > temp && mv temp "$file"

  # add dates to article names
  DATE_DIFF=$(echo $(($(date +%Y%m%d)-20220527)))
  BASE62=($(echo {0..9} {a..z} {A..Z}))
  BASE62DATE=$(for i in $(bc <<< "obase=62; $DATE_DIFF"); do
    echo -n ${BASE62[$(( 10#$i ))]}
  done && echo)
  mv "$file" "${BASE62DATE}_${file}"
done
cd /root/obsidianHosting/

# add template file
cp template.html obsidian_nobel/template.html

# Generate HTML
/root/.nvm/versions/node/v16.15.0/bin/node /root/.nvm/versions/node/v16.15.0/bin/markdown-folder-to-html obsidian_nobel
mv _obsidian_nobel /var/www/
chown -R www-data:www-data /var/www/
