Sherlock_Holmes
===============

Nice debug logger to capture crash info and submit.
Sherlock is on the case!
Sherlock logs events in your app, crashes, memory usage, iOS version, device Type and navigation tracking.

Should an app crash you would be able to see what controller the app crashed on, what was the last event for that controller, what the memory usage was at the time and device info to help you solve the crime.

Implementation:
Added Sherlock.h to your root controller.

To log events in your app use
Sherlock_Sleuth(Event, ControllerName, Data)
Event: the name of the even such as "View Did Load" or "Making API CALL"
ControllerName: The name of the owner of the even like NSStringFromClass([self class])
Data: Additional data to attach to event. In the case of crash this would be the callStack

To Check if there was a crash to report use:
Sherlock_Investigate();
Returns Boolean
Investigate will check for crash log and check if we just crashed
This can be used to fire an alert asking the user to submit the crash data.

To Submit crash data use:
Sherlock_Solve();
Return NSString of JSON data.
This converts the plist of crash data into JSON and returns a JSON string to send to your api.
This then deletes the crash log.