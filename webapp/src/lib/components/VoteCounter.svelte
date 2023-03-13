<script lang="ts">
    import { page } from "$app/stores";
    import { goto, invalidate } from '$app/navigation';
    import { scale } from 'svelte/transition';
    import toast from 'svelte-french-toast';
    import { Confetti } from "svelte-confetti";

    $: activeUrl = $page.url.pathname;

    export let user;
    export let feedback;
    export let userVote;
    
    const performVoting = async (action, userId, feedbackId, voteId = null): Promise<any> =>  {
        
        const data = {
            action,
            userId,
            feedbackId,
            voteId,
        };
        const response = await fetch('/api/vote', {
            method: 'POST',
            body: JSON.stringify(data),
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
    
    }

    const clickVote = async (userId, feedbackId) => {
        if (!userId || !user) {
            goto(`/login/?redirectUrl=${activeUrl}`);
            return;
        }
       
        try {
            await toast.promise(
                performVoting('createVote', userId, feedbackId), 
                {
                    loading: 'Saving ...',
                    success: () => {
                        invalidate('app:feedback');
                        return 'Vote saved!';
                    },
                    error: (msg) => {
                        return `Could not save vote!${!!msg ? `\n\n${msg}` : ''}`;
                    },
                },
            );
        }
        catch (e) {
            console.log(`error during voting ${e}`);
        }
    };

    const clickUnvote = async (userId, feedbackId, voteId) => {
        if (!userId || !user) {
            goto(`/login/?redirectUrl=${activeUrl}`);
            return;
        }

        try {
            await toast.promise(
                performVoting('removeVote', userId, feedbackId, voteId), 
                {
                    loading: 'Saving ...',
                    success: () => {
                        // load new count
                        invalidate('app:feedback');

                        // show confetti

                        return 'Vote removed!'
                    },
                    error: (msg) => {
                        return `Could not remove vote!${!!msg ? `\n\n${msg}` : ''}`;
                    },
                },
            );
        }
        catch (e) {
            console.log(`error during unvoting ${e}`);
        }
    };

</script>

<div>
    <button class="group relative inline-block w-12 h-12 mr-5 border border-gray-800 bg-white rounded" 
        on:click={!!userVote ? clickUnvote(user?.id, feedback?.id, userVote.id) : clickVote(user?.id, feedback?.id)} >
        <svg class="mx-auto w-5 h-5 bg-white" fill="black" viewBox="3 1 18 18" xmlns="http://www.w3.org/2000/svg">
            <path d="M12.354 8.854l5.792 5.792a.5.5 0 01-.353.854H6.207a.5.5 0 01-.353-.854l5.792-5.792a.5.5 0 01.708 0z"></path>
        </svg>
        {#key feedback.voter_count}
        <span class="mx-auto inline-block" in:scale>
            {feedback.voter_count}
        </span>
        {/key}
        <!-- Tooltip -->
        <span class="absolute block hidden group-hover:flex -left-14 -top-3 -translate-y-full w-40 pl-3 pr-3 py-2 bg-gray-500 rounded-lg
                        text-center justify-center text-white text-sm after:content-[''] after:absolute after:left-1/2 after:top-[100%] 
                        after:-translate-x-1/2 after:border-8 after:border-x-transparent after:border-b-transparent after:border-t-gray-500">
        {#if !user}
            Click to login and vote
        {:else}
            Click to {!!userVote ? 'remove' : ''} vote
        {/if}
        </span>
        <!-- End Tooltip -->
        
    </button>
</div>