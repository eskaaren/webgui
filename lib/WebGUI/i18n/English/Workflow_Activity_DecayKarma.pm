package WebGUI::i18n::English::Workflow_Activity_DecayKarma;

our $I18N = {
	'decay factor help' => {
		message => q|How many points of karma should be removed from a user's account when Decay Karma runs?|,
		context => q|the hover help for the decay factor field|,
		lastUpdated => 0,
	},

	'decay factor' => {
		message => q|Decay Factor|,
		context => q|a label indicating how much karma should be deleted from a user's account per run|,
		lastUpdated => 0,
	},

	'minimum karma help' => {
		message => q|What's the minimum amount that a user's karma can decay to?|,
		context => q|the hover help for the minimum karma field|,
		lastUpdated => 0,
	},

	'minimum karma' => {
		message => q|Minimum Karma|,
		context => q|a label indicating the lowest point karma can decay to|,
		lastUpdated => 0,
	},

	'topicName' => {
		message => q|Decay Karma|,
		context => q|The name of this workflow activity.|,
		lastUpdated => 0,
	},

	'decay karma body' => {
		message => q|<p>This workflow activity will cause karma to increase or decrease by a set amount, not by a percentage, if it is above a minimum value specified by the user.  To alter the karma of all users, simple set the karma to a large, negative value.</p>|,
		lastUpdated => 0,
	},

};

1;
