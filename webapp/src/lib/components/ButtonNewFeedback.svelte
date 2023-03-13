
<script lang="ts">
    import ButtonWithTooltip from '$lib/components/ButtonWithTooltip.svelte';

    export let isUserLoggedIn;
    export let companySlug;

</script>

<div class="">
    <a href="{isUserLoggedIn ? '' : '/login?redirectUrl='}/company/{companySlug}/feedback/new">
        <span class="ml-12">
            <ButtonWithTooltip buttonText='+ Create new' 
                                guestTooltip='Click to login and create feedback' 
            />
        </span>
    </a>
</div>