import Toybox.Attention;
import Toybox.System;
import Toybox.Lang;

//! Random vibration pattern generator
class VibrationPattern {

    static function hasVibration() as Boolean {
        return Attention has :vibrate;
    }

    //! Play a random vibration pattern
    //! Attention.vibrate takes Array<[level, duration_ms]>
    static function playSimple() as Void {
        if (!hasVibration()) {
            return;
        }

        var seed = System.getTimer();
        var numVibrations = 1 + (seed % 10);

        var vibrateData = [];
        for (var i = 0; i < numVibrations; i++) {
            // Random level: 50 or 100
            var level;
            if ((seed + i) % 2 == 0) {
                level = 50;
            } else {
                level = 100;
            }
            // Random duration: 100ms or 500ms
            var duration;
            if ((seed + i * 3) % 2 == 0) {
                duration = 100;
            } else {
                duration = 500;
            }
            vibrateData.add([level, duration]);
        }

        try {
            Attention.vibrate(vibrateData);
        } catch (ex) {
            System.println("Vibration error");
        }
    }
}
