import { writable, type Writable } from "svelte/store";

export enum LoadingStatus {
	IDLE,
	LOADING,
	NAVIGATING,
}

type Loader = {
	status: LoadingStatus;
	message: string;
    delay: number;
};

export const DEFAULT_DELAY = 200; //ms

export const newLoader = () => {
	const { set, update, subscribe }: Writable<Loader> = writable({
		status: LoadingStatus.IDLE,
		message: '',
        delay: DEFAULT_DELAY,
	});

	function setNavigate(isNavigating: boolean, customDelay: number = DEFAULT_DELAY) {
		update(() => {
			return {
				status: isNavigating ? LoadingStatus.NAVIGATING : LoadingStatus.IDLE,
				message: '',
                delay: customDelay,
			};
		});
	}

    function setLoading(isLoading: boolean, message: string = '', customDelay: number = 0) {
		update(() => {
			return {
				status: isLoading ? LoadingStatus.LOADING : LoadingStatus.IDLE,
				message: isLoading ? message : '',
                delay: customDelay,
			};
		});
	}

	return {set, update, subscribe, setNavigate, setLoading};
};

export const loading = newLoader();