# $1: output file
# $2: url (https://groups.google.com/forum/message/raw?msg=foobar/topicID/msgID)
__wget_hook() {
  if [[ "$DOWNLOAD_ATTACHMENTS" == "true" ]]; then
    if [[ ! -f "$1" ]]; then
      echo "Invalid File! $1"
    else
      ENGLISH_DATE=`grep "^Date:" "$1" | head -1 | sed -e 's#^Date: \(.*\).#\1#'`
      #DATE_CODE=`date -j -f "%a, %d %b %Y %H:%M:%S %z" "${ENGLISH_DATE}" +"%d_%m_%Y_%H_%M"`
      MSG_ID_PREFIX=`basename $(dirname "$2")`
      MSG_ID_POSTFIX=`basename "$2"`
      DATE_CODE=`TZ=UTC-8 date --date="${ENGLISH_DATE}" --rfc-3339='date'`
      DIR_PREFIX="${DATE_CODE}_${MSG_ID_PREFIX}_${MSG_ID_POSTFIX}"
      GROUP_DIR="/data/${_GROUP}"
      ATTACHMENTS_DIR="${GROUP_DIR}/attachments"
      mkdir -p "${ATTACHMENTS_DIR}" && \
      ripmime \
        --mailbox \
        --no-nameless \
        --name-by-type \
        --overwrite \
        -p "xls" \
        -d "${ATTACHMENTS_DIR}/${DIR_PREFIX}" \
        -i "$1" \
        -q
    fi
  fi
}
