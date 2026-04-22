# REFLECTION 

> Course policy says this reflection must be written by you without AI.
> Use this file as a scaffold, then replace all content with your own writing before submission.

1. Describe your process.

Almost all the apps and projects I created comes from a real-world issue that I'm facing. For this one, I like to make cocktails, but sometimes when I start making them, I find that there are just one or two items missing for me to make a specific drink. It is often a base liquor or just some lemon juice.

So, I decided to create this app. It should be able to track:
1. What I have in my pantry
2. What I have used in the past that is currently missing

It is best that it has an OCR function so that I can just take a picture of my whole pantry, and it will recognize what is in there and what is not.

For the first working version, I wanted to make the OCR work. Beyond that, I am thinking about AI recommendations to let me know what potential drinks I can make if I just need to get one or two more ingredients. UI/UX seems to be a natural part of that process.

2. What AI tools and strategies did you use?

I used ChatGPT and Copilot, but basically just Copilot using the Codex function from ChatGPT. I provided a spec and the skeleton of the whole thing is based on that.

However, there are details that I needed to talk back and forth with the AI to debug and to make the functions work as I expected. For decision making, all the decisions are made based on my own requirements. I didn't use AI's help to make a decision; I just tell the AI what to do.

3. Why did you make those choices?

When I look at the requirements and consider what we have done before, I see that this workflow can address real-life issues I have faced. I specifically wanted to integrate computer vision, or at least image recognition, into this project. Given the timeline, using static images and OCR seems to be the most appropriate fit. The integration with AI helps resolve many of the issues I previously couldn't make work.

Regarding the tradeoffs:
1. Ideal Scope
   If I had more time, I would have developed an OCR system for a camera inside my refrigerator. This would identify the items inside and remind me when they were added and when they are going to go bad, prompting me to cook them in time.
2. Current Constraints
   That direction requires specific hardware to place a camera inside the fridge to ensure an invisible, effortless user experience. Consequently, I decided not to go that route for this project.

4. What changed from your pre-113 approach?

Prior to this, I was working on some personal projects as well, but the big reflection is that I know what I can do now with the AI tools available today. Previously, because I didn't have a deadline or guidance, I wasn't really sure where the limits were or what resources were available for me to use.

This has been a booster for non-CS students to work on "Vibe Coding" projects. Having been a product manager for a long time, I know what I want and what makes a good product. While planning, testing, and iteration have always been in my mind, I feel today's AI is like a very competent software engineer that doesn't really know what to work on unless you tell it what to do. Being a product manager really helped me in this process.

5. What would you do with more time?
I think a better OCR model and improved UI/UX design would be great additions. I would also like to include more pictures. However, due to the time limit and the energy I have available (alongside recruiting and other coursework), I am already satisfied with where it stands.

For the technical debt, I would clean up certain pages—like settings—to make them look better. I would also try to expand the database of cocktails. Right now it is very basic, even though I know there are thousands of cocktails out there. Initially, I tried to include some Chinese cocktails, but I did not do it in the end.

---

## Final checklist before submitting this file
- Replace everything above with your own writing (250–500 words total).
- Keep it specific, honest, and concrete.
- Confirm this reflects your own understanding and work.
