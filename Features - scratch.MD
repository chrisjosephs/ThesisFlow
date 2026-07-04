users should be able to submit a particular journal or newsfeed and the alogirthm should decide what rank of evidence it is (peer reviewed journal, social media post, rumour etc)

users should be able to manually score/override weight for particular pieces of evidence. 

should be a test flag for thesis that only developers can see
this might have nonsense tests in like : 

The Penguin Paradox: "All penguins are black and white. Some old TV shows are black and white. Therefore, some penguins are old TV shows."

The Cat Fallacy: "All cats have four legs. All dogs have four legs. Therefore, all cats are dogs."

"All men are mortal. Socrates is a man. Therefore, Socrates is mortal."


Evidence
│
├── Source
├── Credibility (Platform)
├── Claim
├── Supporting / Contradicting
├── Relevance (AI)
└── User Override (optional)


Users can add a suggestion for a source for new feeds.  But these will be moderated as they are part of the engine

However generally:
1.Personal layer (user-controlled)

Users can create:

Theses
Monitoring profiles
Watch signals
Confidence values (if they're maintaining their own thesis)
Personal notes
Personal RSS feeds (if you choose to support them)

These only affect their own account.

2. Platform layer (moderated)

This is shared by everyone.

Things like:

Source registry
Publisher information
Evidence ranking
Source reliability
Feed metadata
Duplicate detection
Topic classification

These should be curated.



I think **forking** is much more powerful than just "following."

GitHub became successful because people could fork projects instead of only starring them. I think ThesisFlow could have the same idea.

Imagine this:

```text
Original Thesis

"The AI semiconductor supercycle will continue until 2028."

Author:
Alice

Confidence:
82%

Followers:
12,481

Forks:
2,381
```

Then you click **Fork**.

Your version becomes:

```text
"The AI semiconductor supercycle will continue until 2028."

Forked from Alice

Changes:
✓ Added Micron gross margin criterion.
✓ Removed Intel.
✓ Added Samsung HBM qualification.
✓ Monitoring frequency changed to every 5 minutes.
```

Now the system knows the lineage.

---

## Reputation becomes really interesting

Instead of Reddit-style karma, I'd have several scores:

* **Followers**
* **Forks**
* **Accuracy**
* **Evidence quality**
* **Expertise by category**

For example:

```text
John Smith

Investing ⭐⭐⭐⭐⭐
Physics ⭐⭐⭐⭐☆
Politics ⭐☆☆☆☆

Past 12 months:

Theses:
42

Correct:
81%

Average confidence calibration:
Excellent
```

---

## Then the feed becomes amazing

Instead of:

> Trending posts

You have:

> **Trending theses**

For example:

```
🔥 AI Infrastructure Bubble?

92% confidence

Followers:
31,420

Forks:
4,103

Confidence
↓ 6% today

Reason:
Micron guidance weaker than expected.
```

---

## I'd actually avoid likes

I'd rather have:

* Follow
* Fork
* Agree
* Disagree

Because "likes" don't tell you much.

---

## You could even have competing theses

For example:

```
Bitcoin > $500k by 2035

74%

──────────────

Bitcoin < $100k by 2035

18%
```

Users choose which thesis they support.

Years later you can see who was right.

---

## This is where AI becomes useful

The AI shouldn't write everyone's theses.

It should help maintain them.

For example:

> Your thesis confidence dropped from 84% to 78%.

Why?

* Samsung qualified HBM4.
* Micron margin guidance reduced.
* Two supporting articles.
* One contradictory article.

Accept change?

✓ Yes

✗ No

---

## I also think you're missing one metric

Not just **accuracy**, but **calibration**.

Suppose someone predicts:

```
90%
90%
90%
90%
90%
```

They're wrong every time.

Someone else predicts:

```
55%
63%
78%
32%
91%
```

Over years, they're incredibly well calibrated.

That's much harder to game.

So people become known not just for "being right", but for assigning realistic probabilities.

---

The more we talk about ThesisFlow, the less I think it's "an RSS reader with AI."

I think it's closer to **GitHub meets Wikipedia meets prediction markets**.

The central object isn't an article or a post.

It's a **living thesis** that:

* has evidence,
* has a probability/confidence,
* is monitored over time,
* can be followed,
* can be forked,
* gains or loses confidence as new evidence arrives,
* and develops a public history showing exactly how and why it evolved.

That's a genuinely distinctive concept, and I haven't seen another platform built around that core idea.


