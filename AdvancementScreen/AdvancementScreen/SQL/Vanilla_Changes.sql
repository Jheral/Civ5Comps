
INSERT INTO PolicyBranchClasses (Type) VALUES("BRANCHCLASS_SOCIAL_POLICY");
INSERT INTO PolicyBranchClasses (Type) VALUES("BRANCHCLASS_IDEOLOGY");

UPDATE PolicyBranchClasses SET Description	= "TXT_KEY_BRANCHCLASS_SOCIAL_POLICY"	WHERE Type = "BRANCHCLASS_SOCIAL_POLICY";
UPDATE PolicyBranchClasses SET Description	= "TXT_KEY_BRANCHCLASS_IDEOLOGY"		WHERE Type = "BRANCHCLASS_IDEOLOGY";
UPDATE PolicyBranchClasses SET Style		= "SOCIAL_POLICY"						WHERE Type = "BRANCHCLASS_SOCIAL_POLICY";
UPDATE PolicyBranchClasses SET Style		= "IDEOLOGY"							WHERE Type = "BRANCHCLASS_IDEOLOGY";

UPDATE PolicyBranchTypes SET PolicyBranchClass = "BRANCHCLASS_SOCIAL_POLICY"	WHERE PurchaseByLevel = 0;
UPDATE PolicyBranchTypes SET PolicyBranchClass = "BRANCHCLASS_IDEOLOGY"			WHERE PurchaseByLevel = 1;

UPDATE PolicyBranchTypes SET PolicyBranchImage = "Assets/UI/Art/Icons/SocialPoliciesTradition.dds"		WHERE Type = "POLICY_BRANCH_TRADITION";
UPDATE PolicyBranchTypes SET PolicyBranchImage = "Assets/UI/Art/Icons/SocialPoliciesLiberty.dds"		WHERE Type = "POLICY_BRANCH_LIBERTY";
UPDATE PolicyBranchTypes SET PolicyBranchImage = "SocialPoliciesHonor.dds"								WHERE Type = "POLICY_BRANCH_HONOR";
UPDATE PolicyBranchTypes SET PolicyBranchImage = "SocialPoliciesPiety.dds"								WHERE Type = "POLICY_BRANCH_PIETY";
UPDATE PolicyBranchTypes SET PolicyBranchImage = "SocialPoliciesPatronage.dds"							WHERE Type = "POLICY_BRANCH_PATRONAGE";
UPDATE PolicyBranchTypes SET PolicyBranchImage = "SocialPoliciesRationalism.dds"						WHERE Type = "POLICY_BRANCH_RATIONALISM";
UPDATE PolicyBranchTypes SET PolicyBranchImage = "PolicyBranch_Exploration.dds"							WHERE Type = "POLICY_BRANCH_EXPLORATION";
UPDATE PolicyBranchTypes SET PolicyBranchImage = "SocialPoliciesCommerce.dds"							WHERE Type = "POLICY_BRANCH_COMMERCE";
UPDATE PolicyBranchTypes SET PolicyBranchImage = "PolicyBranch_Aesthetics.dds"							WHERE Type = "POLICY_BRANCH_AESTHETICS";
UPDATE PolicyBranchTypes SET PolicyBranchImage = "SocialPoliciesAutocracy.dds"							WHERE Type = "POLICY_BRANCH_AUTOCRACY";
UPDATE PolicyBranchTypes SET PolicyBranchImage = "SocialPoliciesFreedom.dds"							WHERE Type = "POLICY_BRANCH_FREEDOM";
UPDATE PolicyBranchTypes SET PolicyBranchImage = "SocialPoliciesOrder.dds"								WHERE Type = "POLICY_BRANCH_ORDER";