<script lang="ts">
    import { page } from '$app/stores';
    import ButtonWithTooltip from '$lib/components/ButtonWithTooltip.svelte';
    import DisplayName from '$lib/components/DisplayName.svelte';
    import DisplayTime from '$lib/components/DisplayTime.svelte';
    import ReplyComment from '$lib/components/ReplyComment.svelte';

    $: isUserLoggedIn = !!$page.data?.user;

    export let comment;

</script>


    {#if !!comment}

<div class="grid grid-flow-row gap-1 mt-6 pb-4 bg-gray-100 rounded">

    <!-- Author -->
    <div class="mt-4 ml-2">
        <DisplayName user={comment.author_id} />
    </div>
    <!-- End Author -->

    <!-- Content -->
    <div class="mt-5 ml-4 text-gray-800 dark:text-gray-400">
      {@html comment.content}
    </div>
    <!-- End Content -->

    <!-- Time -->
    <div class="mt-4 ml-3 p-0">
        <DisplayTime prefix={'created'} datetime={comment.date_created} /> 
    </div>
    <!-- End Time -->

</div>

    <div class="ml-1 mt-4 p-0 ">
        <ReplyComment {comment} />
    </div>
    
    {/if}


