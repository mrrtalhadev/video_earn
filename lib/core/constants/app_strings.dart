/// Every user-facing string in the app. Keep it in this one file so the app
/// can be renamed or translated (Urdu) in one place.
abstract final class AppStrings {
  // Common
  static const String appName = 'VidEarn';
  static const String appTagline = 'Watch videos. Earn PKR.';
  static const String currency = 'PKR';
  static const String ok = 'OK';
  static const String done = 'Done';
  static const String cancel = 'Cancel';
  static const String confirm = 'Confirm';
  static const String save = 'Save';
  static const String submit = 'Submit';
  static const String retry = 'Retry';
  static const String copy = 'Copy';
  static const String copied = 'Copied to clipboard';
  static const String share = 'Share';
  static const String edit = 'Edit';
  static const String delete = 'Delete';
  static const String add = 'Add';
  static const String close = 'Close';
  static const String yes = 'Yes';
  static const String no = 'No';
  static const String back = 'Back';
  static const String viewAll = 'View all';
  static const String seeAll = 'See All';
  static const String loading = 'Loading…';
  static const String loadMore = 'Load more';
  static const String search = 'Search';
  static const String all = 'All';
  static const String notSet = 'Not set';
  static const String optional = '(optional)';
  static const String youAreOffline = 'You are offline. Some actions are disabled.';
  static const String nothingHere = 'Nothing here yet';
  static const String nothingHereMessage = 'Try another filter, or pull down to refresh.';
  static const String somethingWentWrong = 'Something went wrong';
  static const String goHome = 'Go home';
  static const String pageNotFound = 'Page not found';
  static const String pageNotFoundMessage = 'The page you are looking for does not exist or may have been moved.';

  // Status
  static const String statusPending = 'Pending';
  static const String statusApproved = 'Approved';
  static const String statusRejected = 'Rejected';
  static const String statusActive = 'Active';
  static const String statusInactive = 'Inactive';
  static const String statusLocked = 'Locked';
  static const String statusBlocked = 'Blocked';
  static const String statusExpired = 'Expired';
  static const String statusCompleted = 'Completed';
  static const String statusSubscribed = 'Subscribed';
  static const String statusNotSubscribed = 'Not subscribed';

  // Splash / app state
  static const String maintenanceTitle = 'Under maintenance';
  static const String maintenanceMessage = 'We are improving the app. Please check back shortly.';
  static const String updateRequiredTitle = 'Update required';
  static const String updateRequiredMessage =
      'A newer version of the app is required. Please install the latest version to continue.';
  static const String accountIncompleteTitle = 'Account setup incomplete';
  static const String accountIncompleteMessage = 'Your account profile could not be found. Please contact support.';
  static const String blockedTitle = 'Account blocked';
  static const String blockedMessage = 'Your account has been blocked. Please contact support for help.';
  static const String signOut = 'Sign out';
  static const String checkAgain = 'Check again';

  // Auth
  static const String login = 'Log in';
  static const String loginTitle = 'Welcome back';
  static const String loginSubtitle = 'Log in to continue earning';
  static const String signup = 'Sign up';
  static const String signupTitle = 'Create account';
  static const String signupSubtitle = 'Join and start earning PKR';
  static const String name = 'Full name';
  static const String email = 'Email';
  static const String phone = 'Phone number';
  static const String phoneHint = '03XXXXXXXXX';
  static const String password = 'Password';
  static const String confirmPassword = 'Confirm password';
  static const String referralCodeOptional = 'Referral code (optional)';
  static const String forgotPassword = 'Forgot password?';
  static const String resetPassword = 'Reset password';
  static const String resetPasswordSubtitle = 'Enter your email and we will send you a link to reset your password.';
  static const String sendResetLink = 'Send reset link';
  static const String resetLinkSent = 'Password reset email sent. Please check your inbox.';
  static const String noAccount = "Don't have an account?";
  static const String haveAccount = 'Already have an account?';
  static const String signupSectionDetails = 'Your details';
  static const String signupSectionSecurity = 'Secure your account';
  static const String signupSectionReferral = 'Referral';
  static const String splashWatch = 'Watch';
  static const String splashEarn = 'Earn';
  static const String splashWithdraw = 'Withdraw';
  static const String referralCodeInvalid = 'This referral code is not valid. Fix it or clear the field.';
  static const String signupFailedCleanup = 'We could not finish creating your account. Please try again.';
  static const String logout = 'Log out';
  static const String logoutConfirm = 'Are you sure you want to log out?';
  static const String agreeTerms = 'By signing up you agree to our Terms & Conditions.';

  // Validation
  static const String fieldRequired = 'This field is required';
  static const String invalidEmail = 'Enter a valid email address';
  static const String invalidPhone = 'Enter a valid number (03XXXXXXXXX or +923XXXXXXXXX)';
  static const String passwordTooShort = 'Password must be at least 8 characters';
  static const String passwordsDontMatch = 'Passwords do not match';
  static const String nameTooShort = 'Name must be at least 3 characters';
  static const String invalidAccountHolder = 'Use letters and spaces only (at least 3)';
  static const String invalidAccountNumber = 'Enter 8–24 digits, or a PK IBAN (PK + 22 characters)';
  static const String invalidTransactionId = 'Use 6–40 letters or digits';
  static const String invalidYoutubeUrl = 'Enter a valid YouTube video link';
  static const String invalidUrl = 'Enter a valid http(s) link';
  static const String invalidAmount = 'Enter a valid whole amount';
  static const String invalidPositiveNumber = 'Enter a number greater than 0';
  static const String invalidNumber = 'Enter a valid number';
  static const String invalidReferralFormat = 'Referral codes are 8 letters/digits';
  static const String invalidVersion = 'Use the format 1.0.0';
  static const String screenshotRequired = 'Please attach the payment screenshot';
  static const String packageRequired = 'Please choose a package';
  static String tooLong(int max) => 'Must be $max characters or fewer';
  static String minAmount(String min) => 'Minimum amount is $min';
  static String maxAmount(String max) => 'Maximum amount is $max';

  // Navigation
  static const String navHome = 'Home';
  static const String navWallet = 'Wallet';
  static const String navPromote = 'Promote';
  static const String navProfile = 'Profile';
  static const String navDashboard = 'Dashboard';
  static const String navUsers = 'Users';
  static const String navSubscriptions = 'Orders';
  static const String navWithdrawals = 'Withdrawals';
  static const String navMore = 'More';

  // Home
  static String greeting(String name) => 'Hi, $name 👋';
  static const String availableBalance = 'Available Balance';
  static const String availableTasks = 'Available Tasks';
  static const String seeAllTasks = 'See All Tasks';
  static const String subscribeBannerTitle = 'Unlock all tasks';
  static String subscribeBannerMessage(String price) =>
      'Pay a one-time subscription of $price to start earning from every video.';
  static const String subscribeNow = 'Subscribe now';
  static const String paymentUnderReviewTitle = 'Payment under review';
  static const String paymentUnderReviewMessage =
      'We are verifying your payment. Tasks unlock as soon as it is approved.';
  static const String noTasksTitle = 'No tasks right now';
  static const String noTasksMessage = 'New videos are added regularly. Check back soon.';
  static const String alreadyCompleted = 'You have already completed this task';
  static const String ownVideoNotice = 'You cannot earn from your own promoted video.';
  static const String subscriptionActivatedBanner = 'Your subscription is active. All tasks are unlocked!';
  static const String subscriptionRejectedBanner = 'Your payment was not approved. Open Deposit to see why.';
  static const String withdrawProcessedBanner = 'Your withdrawal request has been reviewed. See History.';
  static String referralBonusBanner(String amount) => 'Referral bonus received: $amount';
  static const String lockedTaskTitle = 'Subscription required';
  static String lockedTaskMessage(String price) =>
      'Subscribe once for $price to unlock every video task and start earning.';
  static const String filterPending = 'Pending';
  static const String filterCompleted = 'Completed';
  static String rewardLabel(String amount) => '+$amount';

  // Video player
  static const String watchAndEarn = 'Watch & Earn';
  static const String watchInstructions =
      'Watch the full video without skipping or leaving the app to earn your reward.';
  static String watchProgress(String watched, String total) => 'Watched $watched / $total';
  static const String seekDetectedTitle = 'Skipping is not allowed';
  static const String seekDetectedMessage = 'The video was skipped, so it will restart from the beginning.';
  static const String leftAppTitle = 'Video interrupted';
  static const String leftAppMessage =
      'You left the app while watching. The video must be restarted from the beginning.';
  static const String restartVideo = 'Restart video';
  static const String play = 'Play';
  static const String pause = 'Pause';
  static const String startingSession = 'Preparing your video…';
  static const String completingTask = 'Verifying and crediting your reward…';
  static const String rewardEarnedTitle = 'Reward earned!';
  static String rewardEarnedMessage(String amount) => '$amount has been added to your balance.';
  static const String notWatchedEnough = 'The video was not fully watched. Please watch it again from the start.';
  static const String videoUnavailable = 'This video cannot be played right now.';
  static const String sessionExpired = 'This viewing session took too long. Please restart the video.';
  static const String stillWatchingTitle = 'Are you still watching?';
  static const String stillWatchingMessage = 'Tap the button below to continue earning.';
  static const String stillWatchingButton = "I'm watching";
  static const String stillWatchingFailed = 'No response — the video will restart from the beginning.';

  // Wallet
  static const String wallet = 'Wallet';
  static const String totalEarned = 'Total Earned';
  static const String referralEarnings = 'Referral Earnings';
  static const String totalWithdrawn = 'Total Withdrawn';
  static const String pendingWithdraw = 'Pending Withdraw';
  static const String completedTasks = 'Completed Tasks';
  static const String withdraw = 'Withdraw';
  static const String deposit = 'Deposit';
  static const String history = 'History';
  static const String recentActivity = 'Recent activity';
  static const String noTransactions = 'No transactions yet';
  static const String noTransactionsMessage = 'Your rewards, deposits and withdrawals will show up here.';
  static const String txTaskReward = 'Video reward';
  static const String txReferralBonus = 'Referral bonus';
  static const String txWithdrawHold = 'Withdrawal request';
  static const String txWithdrawRefund = 'Withdrawal refunded';
  static const String txSubscription = 'Subscription activated';
  static const String txPromote = 'Promotion approved';
  static String balanceAfter(String amount) => 'Balance: $amount';

  // Withdraw
  static const String withdrawTitle = 'Withdraw';
  static const String withdrawAmount = 'Amount (PKR)';
  static const String accountHolderName = 'Account holder name';
  static const String bankName = 'Bank name';
  static const String accountNumber = 'Account number or IBAN';
  static String withdrawMinimumInfo(String min) => 'Minimum withdrawal: $min';
  static String withdrawCooldownInfo(int days) => 'One withdrawal every $days days';
  static const String withdrawNotSubscribed = 'Subscribe to unlock withdrawals.';
  static String withdrawBalanceTooLow(String min) => 'You need at least $min available to withdraw.';
  static String withdrawCooldownActive(String date) => 'Your next withdrawal is available on $date.';
  static const String submitWithdraw = 'Request withdrawal';
  static const String withdrawSubmittedTitle = 'Withdrawal requested';
  static const String withdrawSubmittedMessage =
      'Your request has been submitted. The amount is on hold until an admin reviews it.';
  static const String withdrawConfirmTitle = 'Confirm withdrawal';
  static String withdrawConfirmMessage(String amount, String account) => 'Withdraw $amount to $account?';

  // Subscription
  static const String subscriptionTitle = 'Subscription';
  static const String depositTitle = 'Deposit / Subscribe';
  static const String subscriptionIntro =
      'Transfer the subscription fee to the bank account below, then submit the transaction ID and a screenshot.';
  static const String bankDetails = 'Bank details';
  static const String accountTitle = 'Account title';
  static const String iban = 'IBAN';
  static const String amount = 'Amount';
  static const String transactionId = 'Transaction ID';
  static const String paymentScreenshot = 'Payment screenshot';
  static const String pickScreenshot = 'Tap to attach screenshot';
  static const String changeScreenshot = 'Change';
  static const String compressingImage = 'Preparing image…';
  static const String submitPayment = 'Submit payment';
  static const String subscriptionSubmittedTitle = 'Payment submitted';
  static const String subscriptionSubmittedMessage =
      'Thank you! We will verify your payment and unlock your tasks shortly.';
  static const String alreadySubscribed = 'Your subscription is active. Happy earning!';
  static const String orderPendingTitle = 'Payment under review';
  static const String orderPendingMessage =
      'Your last payment is being verified. You will be able to earn once it is approved.';
  static const String orderRejectedTitle = 'Payment rejected';
  static const String resubmit = 'Submit again';
  static String rejectionReason(String reason) => 'Reason: $reason';
  static const String bankNotConfigured = 'Payment details are not available yet. Please contact support.';
  static const String priceChanged =
      'The subscription price has changed. Please review the new amount and submit again.';

  // Promote
  static const String promoteTitle = 'Promote Your Videos';
  static const String promoteIntro =
      'Get your YouTube video in front of our viewers. Choose a package, pay by bank transfer, and we will add your video to the task list after approval.';
  static const String packages = 'Packages';
  static const String noPackages = 'No promotion packages are available right now.';
  static const String noPackagesAdmin = 'No packages yet';
  static const String noPackagesAdminMessage = 'Create a promotion package so users can promote their videos.';
  static String packageDays(int days) => days == 1 ? '1 day' : '$days days';
  static const String youtubeLink = 'YouTube video link';
  static const String videoTitle = 'Video title';
  static const String videoDescription = 'Video description';
  static const String choosePackage = 'Choose a package';
  static const String submitPromote = 'Submit promotion';
  static const String promoteSubmittedTitle = 'Promotion submitted';
  static const String promoteSubmittedMessage =
      'Your order has been submitted. Your video goes live after an admin approves it.';
  static const String myPromoteOrders = 'My Promote Orders';
  static const String noPromoteOrders = 'No promotions yet';
  static const String noPromoteOrdersMessage = 'Promote a video to reach more viewers. Your orders will appear here.';
  static String promoteRunPeriod(String start, String end) => '$start → $end';

  // Referral
  static const String referralProgram = 'Referral Program';
  static const String yourReferralCode = 'Your referral code';
  static String referralShareMessage(String code, String appName) =>
      'Join $appName and earn PKR by watching videos! Use my referral code $code when you sign up.';
  static const String totalReferred = 'Total referred';
  static const String subscribedReferrals = 'Subscribed';
  static const String referralExplainerTitle = 'How it works';
  static String referralExplainer(String bonus) =>
      'Share your code. When a friend signs up with it and their subscription is approved, you instantly earn $bonus. No bonus is paid before approval.';
  static const String referralPending = 'Pending subscription';
  static String referralBonusEarned(String amount) => 'Bonus earned $amount';
  static const String noReferrals = 'No referrals yet';
  static const String noReferralsMessage = 'Share your code with friends and earn a bonus when they subscribe.';

  // Profile
  static const String profile = 'Profile';
  static const String editProfile = 'Edit profile';
  static const String photoUrl = 'Photo URL';
  static const String profileUpdated = 'Profile updated';
  static const String faq = 'FAQ';
  static const String aboutUs = 'About Us';
  static const String contactUs = 'Contact Us';
  static const String terms = 'Terms & Conditions';
  static const String contactWhatsapp = 'Chat on WhatsApp';
  static const String contactEmail = 'Send email';
  static const String contactPhone = 'Call us';
  static const String address = 'Address';
  static const String noContent = 'Coming soon';
  static const String noContentMessage = 'We are preparing this page. Please check back later.';
  static const String noFaqs = 'No FAQs yet';
  static const String noFaqsMessage = 'Answers to common questions will appear here soon.';
  static const String noFaqsAdminMessage = 'Add your first FAQ to help users find answers quickly.';
  static const String cannotOpenLink = 'Could not open the link.';
  static String memberSince(String date) => 'Member since $date';

  // History
  static const String historyTitle = 'History';
  static const String tabEarnings = 'Earnings';
  static const String tabDeposits = 'Deposits';
  static const String tabWithdrawals = 'Withdrawals';
  static const String subscriptionPayment = 'Subscription payment';
  static String promotePayment(String pkg) => 'Promotion — $pkg';
  static String withdrawTo(String bank) => 'To $bank';
  static String txnIdLabel(String id) => 'Txn ID: $id';
  static const String noEarnings = 'No earnings yet';
  static const String noEarningsMessage = 'Watch videos to start earning. Every reward will be listed here.';
  static const String noDeposits = 'No deposits yet';
  static const String noDepositsMessage = 'Your subscription and promotion payments will appear here.';
  static const String noWithdrawals = 'No withdrawals yet';
  static const String noWithdrawalsMessage = 'Cash out your earnings and track every request right here.';

  // Admin
  static const String adminPanel = 'Admin Panel';
  static const String totalUsers = 'Total Users';
  static const String activeUsers = 'Active Users';
  static const String depositedToday = 'Deposited Today';
  static const String depositedLifetime = 'Deposited Lifetime';
  static const String withdrawnToday = 'Withdrawn Today';
  static const String withdrawnLifetime = 'Withdrawn Lifetime';
  static const String promoteDeposits = 'Promote Deposits';
  static const String pendingWithdrawAmount = 'Pending Withdraw Amount';
  static const String pendingSubscriptions = 'Pending subscriptions';
  static const String pendingWithdrawals = 'Pending withdrawals';
  static const String pendingPromotions = 'Pending promotions';
  static const String pullToRefresh = 'Pull down to refresh';
  static String lastUpdated(String time) => 'Updated $time';

  static const String usersTitle = 'Users';
  static const String searchUsersHint = 'Search name, email or phone';
  static const String filterSubscribed = 'Subscribed';
  static const String filterNotSubscribed = 'Not subscribed';
  static const String filterBlocked = 'Blocked';
  static const String noUsers = 'No users found';
  static const String noUsersMessage = 'Try searching with a different name or email.';
  static const String userNotFound = 'User not found';
  static const String userDetail = 'User details';
  static const String joined = 'Joined';
  static const String subscription = 'Subscription';
  static const String balances = 'Balances';
  static const String referralInfo = 'Referral';
  static const String referredByLabel = 'Referred by';
  static const String referralCode = 'Referral code';
  static const String referralsCount = 'Subscribed referrals';
  static const String depositHistory = 'Deposit history';
  static const String withdrawHistory = 'Withdraw history';
  static const String promoteUsage = 'Promote usage';
  static const String blockUser = 'Block user';
  static const String unblockUser = 'Unblock user';
  static const String blockConfirm = 'Block this user? They will be signed out and unable to use the app.';
  static const String unblockConfirm = 'Unblock this user?';
  static const String userBlocked = 'User blocked';
  static const String userUnblocked = 'User unblocked';

  static const String subscriptionManagement = 'Subscriptions';
  static const String withdrawManagement = 'Withdrawals';
  static const String promoteOrdersManagement = 'Promote Orders';
  static const String promotePlansManagement = 'Promote Plans';
  static const String taskManagement = 'Tasks';
  static const String appSettings = 'App Settings';
  static const String approve = 'Approve';
  static const String reject = 'Reject';
  static const String rejectReasonLabel = 'Reason for rejection';
  static const String rejectReasonRequired = 'Please enter a reason';
  static const String approveConfirmTitle = 'Approve?';
  static const String approveSubscriptionConfirm =
      'Confirm you have verified this payment in the bank statement. The user will be subscribed and any referral bonus paid.';
  static const String approveWithdrawConfirm = 'Confirm you have transferred the money to the account shown.';
  static const String adminTransferRef = 'Transfer reference (optional)';
  static const String approvedSuccess = 'Approved';
  static const String rejectedSuccess = 'Rejected';
  static const String alreadyReviewed = 'This request was already reviewed by another admin.';
  static const String duplicateTxnWarning = 'Duplicate transaction ID';
  static String duplicateTxnDetail(int n) => 'This transaction ID appears on $n other order${n == 1 ? '' : 's'}.';
  static const String viewScreenshot = 'View screenshot';
  static const String screenshotUnavailable = 'Screenshot unavailable';
  static const String noPendingItems = 'All caught up';
  static const String noPendingItemsMessage = 'There are no requests waiting for review.';
  static const String noItems = 'No items';
  static const String noItemsMessage = 'Reviewed requests will be listed here.';
  static String submittedOn(String date) => 'Submitted $date';
  static const String submitted = 'Submitted';
  static const String reviewed = 'Reviewed';
  static String reviewedOn(String date) => 'Reviewed $date';
  static const String tabPending = 'Pending';
  static const String tabApproved = 'Approved';
  static const String tabRejected = 'Rejected';

  // Admin — tasks
  static const String addTask = 'Add task';
  static const String editTask = 'Edit task';
  static const String sortOrderLabel = 'Sort order';
  static const String activeLabel = 'Active';
  static const String loadAndVerify = 'Load & verify';
  static const String verifying = 'Verifying video…';
  static const String verifiedOk = 'Video verified';
  static String verifiedDetail(String duration) => 'Duration $duration';
  static const String verifyFirst = 'Load & verify the video before saving';
  static const String verifyNotEmbeddable = 'This video does not allow embedding. Choose another video.';
  static const String verifyLive = 'Live streams cannot be used as tasks.';
  static String verifyTooLong(int minutes) => 'Video is longer than $minutes minutes.';
  static const String verifyFailed = 'Could not load the video. Check the link and try again.';
  static const String verifyTimeout = 'Timed out while loading the video. Try again.';
  static const String taskSaved = 'Task saved';
  static const String taskDeleted = 'Task deleted';
  static const String deleteTaskConfirm = 'Delete this task permanently? Users keep their completion history.';
  static const String noTasksAdmin = 'No tasks yet';
  static const String noTasksAdminMessage = 'Add your first video so users can start watching and earning.';
  static const String filterAdmin = 'Admin';
  static const String filterPromote = 'Promote';
  static const String filterExpired = 'Expired';
  static const String sourceAdmin = 'Admin';
  static const String sourcePromote = 'Promoted';
  static const String purgeExpired = 'Delete expired tasks';
  static String purgeExpiredConfirm(int n) => 'Delete $n expired task${n == 1 ? '' : 's'}?';
  static String expiresOn(String date) => 'Expires $date';

  // Admin — promote
  static const String approvePromoteHint = 'Load & verify the video, then approve to publish it as a task.';
  static const String addPackage = 'Add package';
  static const String editPackage = 'Edit package';
  static const String packageName = 'Package name';
  static const String packagePrice = 'Price (PKR)';
  static const String packageDurationDays = 'Duration (days)';
  static const String packageDescription = 'Description';
  static const String packageSaved = 'Package saved';
  static const String deactivate = 'Deactivate';
  static const String activate = 'Activate';
  static const String deletePackageConfirm = 'Delete this package?';
  static const String packageInUse =
      'This package is used by existing orders, so it was deactivated instead of deleted.';

  // Admin — settings
  static const String tabPricing = 'Pricing & Rules';
  static const String tabBank = 'Bank Details';
  static const String tabSupport = 'Support';
  static const String tabContent = 'Content';
  static const String tabSystem = 'System';
  static const String subscriptionPrice = 'Subscription price (PKR)';
  static const String videoReward = 'Reward per video (PKR)';
  static const String referralBonus = 'Referral bonus (PKR)';
  static const String minWithdraw = 'Minimum withdrawal (PKR)';
  static const String withdrawCooldownDays = 'Withdraw cooldown (days)';
  static const String minWatchPercent = 'Minimum watch %';
  static const String maxVideoMinutes = 'Max video length (minutes)';
  static const String supportWhatsapp = 'Support WhatsApp (e.g. 923001234567)';
  static const String supportEmail = 'Support email';
  static const String contactPhoneLabel = 'Contact phone';
  static const String contactEmailLabel = 'Contact email';
  static const String contactWhatsappLabel = 'Contact WhatsApp';
  static const String maintenanceMode = 'Maintenance mode';
  static const String maintenanceModeHint = 'Users see a maintenance screen. Admins are not affected.';
  static const String minAppVersion = 'Minimum app version';
  static const String settingsSaved = 'Settings saved';
  static const String settingsMissingTitle = 'Settings not created';
  static const String settingsMissingMessage =
      'Create the default settings and sample promote packages to get started.';
  static const String createDefaultSettings = 'Create default settings';
  static const String defaultsCreated = 'Default settings created';
  static const String confirmPriceChangeTitle = 'Change pricing?';
  static const String confirmPriceChange = 'New prices and rewards apply to future actions only. Continue?';
  static const String faqManage = 'FAQs';
  static const String addFaq = 'Add FAQ';
  static const String editFaq = 'Edit FAQ';
  static const String question = 'Question';
  static const String answer = 'Answer';
  static const String deleteFaqConfirm = 'Delete this FAQ?';
  static const String settingsNotLoaded = 'Settings are not available yet. Please try again later.';
  static const String settingsUnavailable = 'Settings unavailable';
  static const String percentRange = 'Enter a value between 1 and 100';
  static const String adminSecurityNote =
      'The admin account has full control. Use a strong unique password and sign out when not in use.';

  // Dialogs
  static const String areYouSure = 'Are you sure?';
  static const String discardChanges = 'Discard changes?';

  // Errors
  static const String errorGeneric = 'Something went wrong. Please try again.';
  static const String errorNetwork = 'No internet connection. Please check your network and try again.';
  static const String errorTimeout =
      'The request is taking too long. Check your connection and refresh before trying again.';
  static const String errorPermission = 'This action is not allowed. Please refresh and try again.';
  static const String errorNotFound = 'The requested item was not found.';
  static const String errorIndexBuilding =
      'The database is still preparing this view. Please try again in a few minutes.';
  static const String errorUnavailable = 'Service temporarily unavailable. Please try again.';
  static const String errorEmailInUse = 'An account already exists with this email.';
  static const String errorInvalidCredentials = 'Incorrect email or password.';
  static const String errorUserDisabled = 'This account has been disabled.';
  static const String errorWeakPassword = 'Please choose a stronger password.';
  static const String errorTooManyRequests = 'Too many attempts. Please wait a moment and try again.';
  static const String errorUserNotFound = 'No account found with this email.';
  static const String errorImagePick = 'Could not read the selected image.';
  static const String errorImageTooLarge = 'The image is too large even after compression. Try another screenshot.';
  static const String errorReferralCode = 'Could not create a unique referral code. Please try again.';
  static const String errorAlreadyPending = 'You already have a payment under review.';
  static const String errorNotSubscribed = 'An active subscription is required.';
  static const String errorCooldown = 'You can only withdraw once per cooldown period.';
  static const String errorInsufficientBalance = 'Insufficient balance.';
  static const String errorOffline = 'You are offline. Connect to the internet to continue.';
  static const String errorLoadFailed = 'Could not load data.';
}
