# app_watchdogd
`app_watchdogd.sh` is used to automatically relaunch an Android APP which is killed or crashed.

`app_watchdogd.sh` can be run in `/data/data/com.domain.appname/files/` or `/system/xbin/` .

If run `app_watchdogd.sh` without `su -c` , even your device is rooted, `adb shell cat /proc/APP_WATCHDOG_SH_PID/oom_adj` will not be `-17` but `0`, Android system will kill `app_watchdogd.sh` process if not smaller than `0` when memory is low, so you need

    su -c /data/data/com.domain.appname/files/app_watchdogd.sh &

and this one line command above is obviously better than

    /data/data/com.domain.appname/files/app_watchdogd.sh &
    manually find APP_WATCHDOG_SH_PID with `ps | grep /system/bin/sh | grep -c poll_sched)`
    su -c echo -12 > /proc/APP_WATCHDOG_SH_PID/oom_adj
    su -c chmod -r /proc/APP_WATCHDOG_SH_PID/oom_adj

## Usage
For sure your device

* rooted
* [install-supersu](https://github.com/flyskywhy/install-supersu)

### shell test
* $1 pkg_or_kill: pkg e.g. `com.domain.appname` means enable watchdogd; or just `kill` means disable watchdogd
* $2 activity: e.g. `MainActivity` if pkg; null if kill
* $3 timeout_sec: e.g. `5` if pkg; null if kill

```
adb remount
adb push app_watchdogd.sh system/xbin/
adb shell su -c system/xbin/app_watchdogd.sh com.domain.appname MainActivity 5 &
adb shell su -c system/xbin/app_watchdogd.sh kill
```

### react-native APP
Copy as `android/app/src/main/assets/app_watchdogd.sh` .

`utils.js` :
```
import AndroidShell from '@flyskywhy/react-native-android-shell';

export function enableAppWatchdogd({
  shPath = '/system/xbin/app_watchdogd.sh',
  pkg,
  activity = 'MainActivity',
  timeoutSec = 5,
}) {
  AndroidShell.executeCommand(
    'su -c ' + shPath + ' ' + pkg + ' ' + activity + ' ' + timeoutSec + ' &',
    () => {},
  );
}

export function disableAppWatchdogd({
  shPath = '/system/xbin/app_watchdogd.sh',
  callback = () => {},
}) {
  AndroidShell.executeCommand('su -c ' + shPath + ' kill', callback);
}
```

`Navigation.js` :
```
if (Platform.OS !== 'web') {
  var RNFS = require('react-native-fs');
}
import AndroidShell from '@flyskywhy/react-native-android-shell';
import RNExitApp from 'react-native-exit-app';
import * as utils from '../utils';

const shPath = `${RNFS.DocumentDirectoryPath}/app_watchdogd.sh`;

class Navigation extends Component {

...

  componentDidMount() {
    this.enableAppWatchdogd();
  }

  enableAppWatchdogd = async () => {
    if (Platform.OS === 'android') {
      if (!(await RNFS.exists(shPath))) {
        await RNFS.copyFileAssets('app_watchdogd.sh', shPath); // /data/data/com.domain.appname/files/app_watchdogd.sh
      }

      AndroidShell.executeCommand(
        'su -c dumpsys window | grep mCurrentFocus',
        (activity) => {
          let a = activity
            .replace(/\n/, '')
            .replace(/^.* .* /, '')
            .replace('}', ''); // com.domain.appname/com.domain.appname.MainActivity
          let pkg = a.replace(/\/.*/, ''); // com.domain.appname
          utils.enableAppWatchdogd({ // if APP exit abnormally (killed or crashed), will be relaunched
            shPath,
            pkg,
          });
        },
      );

      // above have a small bug: after adb install then first launch, pkg could be `com.android.systemui` (from mCurrentFocus)
      // below works well if you can `import {applicationId} from 'expo-application'`
      // utils.enableAppWatchdogd({ // if APP exit abnormally (killed or crashed), will be relaunched
      //   shPath,
      //   pkg: applicationId,
      // });
    }
  };

  onBackPress = async () => {
    if (USER_PRESS_ANDROID_BACK_KEY_TWICE) {
      if (Platform.OS === 'android') {
        utils.disableAppWatchdogd({ // if APP exit normally (by user), will disable watchdogd
          shPath,
          callback: RNExitApp.exitApp,
        });
      } else {
        RNExitApp.exitApp();
      }
    }
  };

...

}
```

### pure Android APP
Copy as `android/app/src/main/assets/app_watchdogd.sh` when building, save as `/data/data/com.domain.appname/files/app_watchdogd.sh` when running, then `su -c /data/data/com.domain.appname/files/app_watchdogd.sh &` from Java.
