users
-----
+ id
+ username
+ email
+ password_hash
+ avatar_url
+ bio
+ created_at
+ updated_at


theses
-------
+ id
+ owner_user_id
+ title
+ summary
+ description
+ status
+ visibility
+ current_confidence
+ confidence_rationale
+ relevance_score
+ monitoring_profile_id
+ default_evidence_weight
+ created_at
+ updated_at


thesis_confidence_history
-------------------------
+ id
+ thesis_id
+ confidence_before
+ confidence_after
+ change_reason
+ generated_by
+ created_at


documents
---------
A document is a piece of information ingested by the platform.

    Examples:
    
    - RSS article
    - Manual URL
    - Peer-reviewed journal
    - SEC filing
    - PDF
    - Blog post
    - Government publication
    - Social media post
    - YouTube transcript
    - Email
    - Book

+ id
+ source_id
+ document_type
+ title
+ url
+ published_at
+ summary
+ raw_text
+ credibility
+ content_hash
+ created_at


document_type
-------------
[
RSS_ARTICLE,
MANUAL_URL,
JOURNAL,
SEC_FILING,
PDF,
BLOG,
GOVERNMENT_PUBLICATION,
SOCIAL_POST,
YOUTUBE_TRANSCRIPT,
EMAIL,
BOOK,
OTHER
]


thesis_evidence
---------------
Represents the relationship between a Thesis and a Document.

A document becomes "evidence" only in the context of a thesis.

+ id
+ thesis_id
+ document_id

+ stance

Where stance is:

[
SUPPORTS,
CONTRADICTS,
NEUTRAL
]

+ relevance
+ confidence_impact

+ user_override
+ override_reason

+ created_at


sources
-------
Represents the publisher or origin.

    Examples:
    
    Reuters
    
    Nature
    
    NASA
    
    Micron Investor Relations
    
    United States SEC

+ id
+ name
+ source_type
+ homepage
+ credibility
+ platform_managed
+ created_at


source_type
-----------
[
GOVERNMENT,
COMPANY,
NEWS,
PEER_REVIEWED_JOURNAL,
SOCIAL,
BLOG,
FORUM,
INDIVIDUAL,
OTHER
]


source_endpoints
----------------

Represents the mechanism used to ingest information.

Examples:

RSS

Atom

REST API

Manual URL

Web Scraper

Webhook

+ id
+ source_id
+ endpoint_type
+ endpoint_url
+ enabled
+ last_checked
+ etag
+ last_modified


endpoint_type
-------------
[
RSS,
ATOM,
API,
SCRAPER,
MANUAL,
WEBHOOK
]


monitoring_profiles
-------------------

+ id
+ name
+ refresh_interval_seconds
+ estimated_cost
+ description


criteria
--------

+ id
+ thesis_id
+ description
+ notes
+ type
+ weight
+ impact_if_confirmed
+ current_fulfillment

Where type is:

[
SUPPORT,
FALSIFY,
WATCH_SIGNAL
]


alerts
------

+ id
+ user_id
+ thesis_id
+ alert_type
+ message
+ read_at
+ created_at


comments
--------

+ id
+ thesis_id
+ user_id
+ body
+ created_at


tags
----

+ id
+ name


thesis_tags
-----------

+ thesis_id
+ tag_id


thesis_forks
------------

+ parent_thesis_id
+ child_thesis_id
+ forked_by
+ created_at


claims
------

A document contains one or more claims.

Claims are the fundamental units of reasoning inside ThesisFlow.

+ id
+ canonical_statement
+ subject
+ predicate
+ object


document_claims
---------------

Many-to-many relationship between documents and claims.

Multiple documents may contain the same claim.

+ document_id
+ claim_id


claim_relationships (Future)
----------------------------

Allows claims to support, contradict or refine one another.

+ id
+ claim_a_id
+ claim_b_id
+ relationship_type


relationship_type
-----------------

[
SUPPORTS,
CONTRADICTS,
DUPLICATES,
REFINES,
DEPENDS_ON
]