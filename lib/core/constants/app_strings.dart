class AppStrings {
  AppStrings._();

  // App Info
  static const String appName = 'Audio Meeting';
  static const String appVersion = '1.0.0';

  // Authentication
  static const String login = 'Login';
  static const String logout = 'Logout';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String forgotPassword = 'Forgot Password?';
  static const String enterEmail = 'Enter your email';
  static const String enterPassword = 'Enter your password';
  static const String welcomeBack = 'Welcome Back';
  static const String loginToContinue = 'Login to continue to your account';

  // Home Screen
  static const String home = 'Home';
  static const String createMeeting = 'Create Meeting';
  static const String joinMeeting = 'Join Meeting';
  static const String meetingHistory = 'Meeting History';
  static const String enterMeetingCode = 'Enter Meeting Code';
  static const String join = 'Join';

  // Meeting
  static const String meeting = 'Meeting';
  static const String startMeeting = 'Start Meeting';
  static const String endMeeting = 'End Meeting';
  static const String leaveMeeting = 'Leave Meeting';
  static const String participants = 'Participants';
  static const String mute = 'Mute';
  static const String unmute = 'Unmute';
  static const String recording = 'Recording';
  static const String recordingInProgress = 'Recording in progress';
  static const String meetingCode = 'Meeting Code';
  static const String duration = 'Duration';
  static const String host = 'Host';
  static const String you = 'You';

  // Admin
  static const String admin = 'Admin';
  static const String adminPanel = 'Admin Panel';
  static const String manageUsers = 'Manage Users';
  static const String createUser = 'Create User';
  static const String activeMeetings = 'Active Meetings';
  static const String totalUsers = 'Total Users';
  static const String userManagement = 'User Management';

  // Validation Messages
  static const String emailRequired = 'Email is required';
  static const String passwordRequired = 'Password is required';
  static const String invalidEmail = 'Please enter a valid email';
  static const String passwordTooShort = 'Password must be at least 6 characters';
  static const String meetingCodeRequired = 'Meeting code is required';

  // Error Messages
  static const String somethingWentWrong = 'Something went wrong';
  static const String noInternetConnection = 'No internet connection';
  static const String sessionExpired = 'Session expired, please login again';
  static const String deviceMismatch = 'Logged in from another device';
  static const String meetingNotFound = 'Meeting not found';
  static const String meetingEnded = 'Meeting has ended';
  static const String permissionDenied = 'Permission denied';
  static const String microphonePermissionRequired = 'Microphone permission is required';

  // Success Messages
  static const String loginSuccessful = 'Login successful';
  static const String meetingCreated = 'Meeting created successfully';
  static const String recordingSaved = 'Recording saved successfully';
  static const String userCreated = 'User created successfully';

  // Confirmation Messages
  static const String endMeetingConfirmation = 'Are you sure you want to end this meeting?';
  static const String leaveMeetingConfirmation = 'Are you sure you want to leave this meeting?';
  static const String logoutConfirmation = 'Are you sure you want to logout?';
  static const String deleteRecordingConfirmation = 'Are you sure you want to delete this recording?';

  // Buttons
  static const String cancel = 'Cancel';
  static const String confirm = 'Confirm';
  static const String ok = 'OK';
  static const String yes = 'Yes';
  static const String no = 'No';
  static const String save = 'Save';
  static const String delete = 'Delete';
  static const String edit = 'Edit';
  static const String search = 'Search';

  // Status
  static const String active = 'Active';
  static const String inactive = 'Inactive';
  static const String online = 'Online';
  static const String offline = 'Offline';
  static const String waiting = 'Waiting';

  // Date & Time
  static const String today = 'Today';
  static const String yesterday = 'Yesterday';
  static const String lastSevenDays = 'Last 7 Days';

  // Empty States
  static const String noMeetingsFound = 'No meetings found';
  static const String noRecordingsFound = 'No recordings found';
  static const String noUsersFound = 'No users found';
  static const String noDataAvailable = 'No data available';
}