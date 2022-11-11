#!/usr/bin/env bash
set -e;
set -u;

# save the news page somewhere so we don't repeatedly query the server
INPUT_PATH=${INPUT_FILENAME:-"bin/news.html"}
INPUT_FILENAME=$(basename "${INPUT_PATH}")
OUTPUT_ASSETS_DIR=${OUTPUT_ASSETS_DIR:-"public/assets/uploads"}
OUTPUT_POSTS_DIR=${OUTPUT_POSTS_DIR:-"src/pages/blog/posts"}

# selectors taken from chrome inspect element > copy jspath
commentTableSelector="body > font > center > center:nth-child(13) > table:nth-child(7) > tbody > tr > td:nth-child(1) > table > tbody > tr > td > center > table"
allNewsSelector="body > font > center > center:nth-child(13) > table:nth-child(7) > tbody > tr > td:nth-child(1) > table > tbody > tr:nth-child(1)"
titleSelector="body > font > center > center:nth-child(13) > table:nth-child(7) > tbody > tr > td:nth-child(1) > table > tbody > tr:nth-child(2n+1)"
bodySelector="body > font > center > center:nth-child(13) > table:nth-child(7) > tbody > tr > td:nth-child(1) > table > tbody > tr:nth-child(2n+2)"
TEMPDIR=$(mktemp -d)

cp "${INPUT_PATH}" "${TEMPDIR}"
pushd "${TEMPDIR}"
mkdir -p "${OUTPUT_ASSETS_DIR}" "${OUTPUT_POSTS_DIR}"

htmlq \
    --filename "${INPUT_FILENAME}" \
    --pretty \
    --remove-nodes "${commentTableSelector}" \
    --remove-nodes "${allNewsSelector}" \
    "${titleSelector}" \
    | split -p "<tr>" -d -a 3 - title-

htmlq \
    --filename "${INPUT_FILENAME}" \
    --pretty \
    --remove-nodes "${commentTableSelector}" \
    --remove-nodes "${allNewsSelector}" \
    "${bodySelector}" \
    | split -p "<tr>" -d -a 3 - body-


for f in title-*; do
    n=$(echo "${f}" | cut -d"-" -f2)
    titleText=$(htmlq -f title-$n --text --pretty --remove-nodes "font" "p" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
    titleDateAuthor=$(htmlq -f title-$n --text --pretty "font" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | tr -d '()')
    titleDate=$(echo "${titleDateAuthor}" | cut -d'-' -f1 | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
    titleAuthor=$(echo "${titleDateAuthor}" | cut -d'-' -f2 | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

    bodyImage=$(htmlq -f body-$n --attribute src img | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
    bodyImageCaption=$(htmlq -f body-$n --text i | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | tr -d '\n\r')
    bodyText=$(htmlq -f body-$n --text --pretty --remove-nodes i --remove-nodes img | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | uniq)

    mdFile="${OUTPUT_POSTS_DIR}/post-${n}.md"
    touch "${mdFile}"

    # templating lol
    echo "---" > "${mdFile}"
    echo "title: ${titleText}" >> "${mdFile}"
    echo "date: ${titleDate}" >> "${mdFile}"
    echo "author: ${titleAuthor}" >> "${mdFile}"

    # if we have image info
    if [ ! -z ${bodyImage} ]; then
        # check src dir for image, fetch if missing
        popd
        if [ ! -f "${OUTPUT_ASSETS_DIR}/post-${n}.jpg" ]; then
            echo "Image not found in ${OUTPUT_ASSETS_DIR}/post-${n}.jpg, fetching.."
            pushd "${TEMPDIR}"
            curl --silent -o "${OUTPUT_ASSETS_DIR}/post-${n}.jpg" "https://duluthmakerspace.com${bodyImage}"
            popd
        fi
        pushd "${TEMPDIR}"

        echo "image: /assets/uploads/post-${n}.jpg" >> "${mdFile}"
    fi

    [ ! -z "${bodyImageCaption}" ] && echo "description: ${bodyImageCaption}" >> "${mdFile}"
    echo "layout: ../../../layouts/Post.astro" >> "${mdFile}"
    echo "---" >> "${mdFile}"
    echo "${bodyText}" >> "${mdFile}"

    # clean up
    rm "title-${n}" "body-${n}"
done

popd

echo "files written to: ${TEMPDIR}"
echo "syncing with sourcetree.."

rsync -avzhc "${TEMPDIR}/${OUTPUT_POSTS_DIR}/" "${OUTPUT_POSTS_DIR}/"
rsync -avzhc "${TEMPDIR}/${OUTPUT_ASSETS_DIR}/" "${OUTPUT_ASSETS_DIR}/"
