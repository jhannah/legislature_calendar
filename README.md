# LegiScan Public Datasets

## CSV Datasets
Compared to the JSON datasets the CVS collection represents a portable
subset of LegiScan data within the limitation of the file format. These files
are meant to be processed by another application, typically Excel or Access.

See [LegiScan Datasets](https://legiscan.com/datasets) for more information.

## State Links
Note that state URLs are not actively maintained for history data in past
sessions and may no longer be accessible. The LegiScan URL for each object is
a permalink that will always be valid.

## bills.csv
List of bills and their basic details along with links to LegiScan and state pages.

	bill_number - Bill number
	bill_id - LegiScan bill identifier
	session_id - LegiScan session identifier
	status - Status value for bill
	status_desc - Description of bill status value
	status_date - Date of status change
	title - Short title of bill
	description - Long title of bill
	committee_id - LegiScan committee identifier
	committee - Pending committee name
	last_action_date - Date of last action
	last_action - Description of last action
	url - LegiScan URL for bill detail
	state_link - State URL for bill detail

## history.csv
List of history steps / actions taken, keyed to `bills.csv` by `bill_id`.

	bill_id - LegiScan bill identifier
	date - Date of history step
	chamber - Chamber the action occurred in
	sequence - Ordered sequence of history step
	action - Description of history step

## people.csv
List of legisltors and their basic details along with third party identifiers.

	people_id - LegiScan person identifier
	name - Full name
	first_name - First name
	middle_name - Middle name
	last_name - Last name
	suffix - Suffix
	nickname - Nickname
	party_id - LegiScan political party identifier (1, 2, 3)
	party - Political party descirption (D, R, I)
	role_id - LegiScan legislative role identifier (1, 2)
	role - Legilsative role description (House, Senate)
	district - Legislative district
	followthemoney_eid - Identifier for [Follow The Money](https://www.followthemoney.org/)
	votesmart_id - Identifier for [Vote Smart](https://votesmart.org/)
	opensecrets_id - Identifier for [OpenSecrets](https://www.opensecrets.org/)
	ballotpedia - Identifier for [Ballotpedia](https://ballotpedia.org/)
	knowwho_pid - Identifier for [KnowWho](https://knowwho.com/)
	committee_id - Non-zero if the "person" is actually a committee sponsor

## rollcalls.csv
List of roll calls for each bill, keyed to `bills.csv` by `bill_id`.

	bill_id - LegiScan bill identifier
	roll_call_id - LegiScan roll call identifier
	date - Date of the roll call
	chamber - Chamber the roll call occurred in
	description - Description of the roll call
	yea - Number of Yeas
	nay - Number of Nays
	nv - Number of NV/Abstains
	absent - Number of Absences
	total - Total votes

## sponsors.csv
List of sponsors for each bill, keyed to `bills.csv` and `people.csv` by `bill_id`
and `people_id` respectively.

	bill_id - LegiScan bill identifier
	people_id - LegiScan person identifer
	position - Ordered position of the sponsor in list

## votes.csv
List of individual vote details for each roll call, keyed to `rollcalls.csv` and
`people.csv` by `roll_call_id` and `people_id` respectively.

	roll_call_id - LegiScan roll call identifier
	people_id - LegiScan person identifier
	vote - Vote integer value (1, 2, 3, 4)
	vote_desc - Vote description (Yea, Nay, NV, Absent)

## documents.csv
List of document links associated with each bill, keyed to `bills.csv` by `bill_id`.

	bill_id - LegiScan bill identifier
	document_type - Type of document (text, amendment, supplement)
	document_id - LegiScan identifier (doc_id, amendment_id, supplement_id)
	document_size - Size of document file
	document_mime - MIME type of the document file
	document_desc - Document description
	url - LegiScan URL for document
	state_link - State URL for document