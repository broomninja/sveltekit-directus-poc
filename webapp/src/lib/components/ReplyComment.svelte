<script lang="ts">
    import { fade } from 'svelte/transition';
    import { browser } from '$app/environment';
    import { enhance, type SubmitFunction } from '$app/forms';
    import { invalidate } from '$app/navigation';
    import { page } from '$app/stores';
    import ButtonWithTooltip from '$lib/components/ButtonWithTooltip.svelte';
    import toast from 'svelte-french-toast';
    import DOMPurify from 'isomorphic-dompurify';
    import { z } from 'zod';
    import { CommentContentConstraint, IdConstraint } from '$lib/validation/feedback';

    export let comment;

    let user = $page.data.user;
    let isUserLoggedIn = !!user;
    let activeUrl = $page.url.pathname;

	let showCommentReplyForm: boolean = false;

    let formData: HTMLFormElement = {
        content: '',
        userId: user?.id,
        replyToCommentId: comment?.id,
    }

    const schema = z.object({ 
                        content: CommentContentConstraint,
                        userId: IdConstraint,
                        replyToCommentId: IdConstraint,
                   });

    const saveComment = async (data: FormData): Promise<any> =>  {

        const validation = schema.safeParse(data);

        if (!validation.success) {
            return new Promise((resolve, reject) => {
                reject('Invalid comment content!');
            });
        }

        let cleanData = validation.data;
        cleanData.content = DOMPurify.sanitize(validation.data.content);

        return new Promise((resolve, reject) => {
                reject('Feature not implemented yet!');
        });

/*        
        const response = await fetch(`${activeUrl}/comment`, {
            method: 'POST',
            body: JSON.stringify(cleanData),
            headers: {
                'content-type': 'application/json',
            },
        });

        const body = await response.json();
        
        return new Promise((resolve, reject) => {
            if (body.success) {
                resolve(200);
            } else {
                reject(body.errorMessage ?? '');
            }
        });
  */  
    }

    const handleReply: SubmitFunction = async () => {

        // user may have logged out from another tab while editing the comment on the current tab
        // TODO: user will lose the comment if we redirect to login page? maybe save to localStorage
        if (!isUserLoggedIn) {
            goto(`/login/?redirectUrl=${activeUrl}`);
            return;
        }

        try {
            await toast.promise(
                saveComment(formData),
                {
                    loading: 'Saving ...',
                    success: () => {
                        invalidate('app:feedback');
                        showCommentReplyForm = false;
                        formData.content = '';
                        // TODO: scroll to the bottom
                        return 'Comment added!';
                    },
                    error: (msg) => {
                        return `Could not save comment!${!!msg ? `\n\n${msg}` : ''}`;
                    },
                },
            );
        }
        catch (e) {
            console.log(`error when creating comment ${e}`);
        }
    };

	const replyMaxLength: number = 500;
	$: charsRemaining = replyMaxLength - formData.content.length;

</script>

<div>
{#if (isUserLoggedIn)}
    
    <label for="reply-comment-toggle_{comment.id}" class="cursor-pointer group relative inline-block ml-0 py-2 px-4 justify-center items-center 
        gap-2 rounded-md bg-blue-100 border border-transparent font-semibold text-blue-500 hover:text-white hover:bg-blue-500 
        focus:outline-none focus:ring-2 ring-offset-white focus:ring-blue-500 focus:ring-offset-2 transition-all text-sm 
        dark:focus:ring-offset-gray-800 dark:bg-gray-900 dark:hover:bg-blue-400 dark:text-white">
            Reply to comment
    </label>

    <input id="reply-comment-toggle_{comment.id}" type="checkbox" class="sr-only peer/reply-toggle" bind:checked={showCommentReplyForm} />

    {#if showCommentReplyForm}
    <form
        in:fade
        method="POST"
        on:submit|preventDefault={handleReply}
        class="flex-col hidden gap-4 mt-5 reply-form peer-checked/reply-toggle:flex md:flex-row md:items-start"
    >
        <textarea
            id="reply"
            name="content"
            placeholder="Type your reply here"
            rows="3"
            required
            maxlength={replyMaxLength}
            bind:value={formData.content}
            class="bg-gray-100 rounded-[5px] py-3 px-6 placeholder:text-sm md:placeholder:text-sm placeholder:text-gray-400 
    text-gray-900 text-sm md:text-sm w-full outline-none ring-blue-400 focus-within:ring-1 hover:ring-1"
        />

        <input type="hidden" name="userId" bind:value={formData.userId} />
        <input type="hidden" name="replyToCommentId" bind:value={formData.commentId} />

        <div class="flex items-center justify-between md:flex-col-reverse md:justify-center md:h-full md:gap-2 
        md:min-w-[120px]">
            <div>
                {#if browser}
                    <p class="text-xs text-gray-400 md:text-sm whitespace-nowrap">
                        {charsRemaining} characters left
                    </p>
                {:else}
                    <p class="text-xs text-gray-400 md:text-sm whitespace-nowrap">Max {replyMaxLength} characters</p>
                {/if}
            </div>
            <div>
                <button type="submit" disabled={!formData.content.trim()} class="disabled:opacity-30 mt-6 py-2 px-4 rounded-md bg-blue-100 border border-transparent font-semibold text-blue-500 hover:text-white hover:bg-blue-500 
            focus:outline-none focus:ring-2 ring-offset-white focus:ring-blue-500 focus:ring-offset-2 transition-all 
            dark:focus:ring-offset-gray-800 dark:bg-gray-900 dark:hover:bg-blue-400 dark:text-white">
                    Send
                </button>
            </div>
        </div>
    </form>
    {/if}
{:else}

    <a href={`/login/?redirectUrl=${activeUrl}`}>
        <span>
            <ButtonWithTooltip buttonText='Reply to comment' 
                    guestTooltip='Click to login and reply' 
            />
        </span>
    </a>
 
{/if}
</div>