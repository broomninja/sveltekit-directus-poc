<script lang="ts">
    import { page } from '$app/stores';
    import ButtonWithTooltip from '$lib/components/ButtonWithTooltip.svelte';
    import Comment from '$lib/components/Comment.svelte';

    $: isUserLoggedIn = !!$page.data?.user;

    export let comments;

    // Do not show Reply button if no comments
    $: showReplyButton = comments?.length > 0;

</script>

<div>
    {#each comments as comment}
    <div>
      <Comment {comment}/>
    </div>
    {:else}
    <div class="mt-6 ml-1">
        No comments found
    </div>
    {/each}
</div>
