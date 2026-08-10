package com.manurya.sajhya_patient_app

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Block screenshots, screen recording, and the recent-apps thumbnail. The
        // app displays diagnoses and prescriptions, which should not be capturable
        // by other apps or left rendered in the task switcher.
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE
        )
        super.onCreate(savedInstanceState)
    }
}
