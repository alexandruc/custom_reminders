import Toybox.Attention;
import Toybox.System;
import Toybox.Lang;

class VibrationPattern {

    static function hasVibration() as Boolean {
        return Attention has :vibrate;
    }

    //! Play a 2-second vibration at full intensity.
    static function playLong() as Void {
        if (!hasVibration()) {
            return;
        }
        try {
            Attention.vibrate([new Attention.VibeProfile(100, 2000)]);
        } catch (ex) {
            System.println("Vibration error: " + ex);
        }
    }
}
