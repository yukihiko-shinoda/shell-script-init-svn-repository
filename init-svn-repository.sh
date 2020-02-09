#!/usr/bin/env sh
set -eu

# Environment Variable
# * User name and password is reading in bellow while loop by using eval.
USER_NAME=${SVN_USER_NAME}
USER_PASSWORD=${SVN_USER_PASSWORD}
REPOSITORY_NAME=${SVN_REPOSITORY_NAME:-project-in-svn}

# Constant
PATH_SVN_HOME=/var/opt/svn
REPO_DIR="${PATH_SVN_HOME}"/"${REPOSITORY_NAME}"
PATH_SVN_SERVE_CONF="${REPO_DIR}"/conf/svnserve.conf
PATH_SVN_PASSWD="${REPO_DIR}"/conf/passwd

rm -rf "${REPO_DIR}"
svnadmin create "${REPO_DIR}"

sed -i 's/#\sauth-access\s=\swrite/auth-access = write/' "${PATH_SVN_SERVE_CONF}"
sed -i 's/#\spassword-db\s=\spasswd/password-db = passwd/' "${PATH_SVN_SERVE_CONF}"

# shellcheck disable=SC2154
echo "${USER_NAME} = ${USER_PASSWORD}" >> "${PATH_SVN_PASSWD}"

cp -fp "${REPO_DIR}"/hooks/pre-revprop-change.tmpl "${REPO_DIR}"/hooks/pre-revprop-change
# shellcheck disable=SC2016
regex='echo\s"Changing\srevision\sproperties\sother\sthan\ssvn:log\sis\sprohibited"\s>&2'
sed -e "/${regex}/ s/^#*/# /" -i "${REPO_DIR}"/hooks/pre-revprop-change
regex='exit\s1'
replace_content=$(cat <<'END_HEREDOC'
# exit 1
exit 0
END_HEREDOC
)
# @see https://stackoverflow.com/a/1252191/12721873
replace_content=$(echo "${replace_content}" | sed ':a;N;$!ba;s/\n/\\n/g')
replace_content=$(echo "${replace_content}" | sed 's/\&/\\&/g')
sed -i "s/${regex}/${replace_content}/" "${REPO_DIR}"/hooks/pre-revprop-change
chmod +x "${REPO_DIR}"/hooks/pre-revprop-change
