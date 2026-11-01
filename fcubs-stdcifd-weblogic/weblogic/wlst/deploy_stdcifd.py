# WLST deployment helper for the clone-owned STDCIFD WAR.
# Set WLS_ADMIN_URL, WLS_USER, WLS_PASSWORD, WLS_TARGET, and WAR_PATH
# in the shell before running this script with the WebLogic WLST interpreter.
import os

def required(name):
    value = os.environ.get(name)
    if not value:
        raise Exception('Required environment variable is not set: ' + name)
    return value

admin_url = required('WLS_ADMIN_URL')
user = required('WLS_USER')
password = required('WLS_PASSWORD')
target = required('WLS_TARGET')
war_path = required('WAR_PATH')
app_name = os.environ.get('WLS_APP_NAME', 'stdcifd-weblogic')

try:
    connect(user, password, admin_url)
    existing = [app for app in cmo.getAppDeployments() if app.getName() == app_name]
    if existing:
        print('Application already exists. Redeploying: ' + app_name)
        redeploy(app_name, war_path, targets=target, upload='true', block='true')
    else:
        print('Deploying: ' + app_name)
        deploy(app_name, war_path, targets=target, upload='true', block='true')
    print('Deployment command completed. Verify application state in the console.')
finally:
    try:
        disconnect()
    except:
        pass
