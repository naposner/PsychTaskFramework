function RA(observer)
% Written side-by-side with RA_GAINS1

%% Setup
settings = config();
KbName(settings.device.KbName);

% Set random generator
s = RandStream.create('mt19937ar', 'seed', sum(100*clock));
RandStream.setGlobalStream(s);

% Find-or-create participant data file *in appropriate location*
fname = [num2str(observer) '.mat'];
folder = fullfile(pwd, 'data');
fname = [folder filesep fname];
[ Data, participantExisted ] = loadOrCreate(observer, fname); % TODO: Create

% TODO: Prompt experimenter if this is correct
if participantExisted
  disp('Participant file exists, reusing...')
else
  disp('Participant has no file, creating...')
end

% Save participant ID + date
% TODO: Prompt for correctness before launching PTB?
Data.observer = observer;
Data.date = datestr(now, 'yyyymmddTHHMMSS'); % FIXME: This should be conditional
if mod(observer, 2) == 0
    Data.refSide = 1; % left
    settings.perUser.refSide = 1;
else
    Data.refSide = 2; % right
    settings.perUser.refSide = 2;
end

%% Generate trials/blocks - or check whether it's been generated before?
% Generate order of trials in a single table, then iterate n at a time?
% Generate a number of separate blocks, then iterate through them?
% Just run trials with ad-hoc intermissions? (This was the old way, sort of)

% 1. Bring in levels from `settings`
% 2. Define the repeat row
% 3. Bring in RA_generateTrialOrder to create `trials`
% 4. Add the constant columns (stakes_loss, reference_value, trial_type)
% 5. Mix around ITI order
% 6. Pass row subsets to runBlock
%
% TODO: Mix in with losses right here? How?

repeatRow = table(4, 0.5, 0, randperm(2, 1), 'VariableNames', {'stakes', 'probs', 'ambigs', 'colors'});
repeatIndex = [1 32 63 94]; % TODO: Derive from block.length and repeatPosition
% TODO: Extract the row injection into a separate function done after the fact, so that it can be done without knowledge of the result
trials = RA_generateTrialOrder(settings.game.levels, ...
  repeatRow, repeatIndex);
numTrials = height(trials);
trials.stakes_loss = repmat(settings.game.levels.stakes_loss, numTrials, 1);
trials.reference = repmat(settings.game.levels.reference, numTrials, 1);

perBlockITIs = settings.game.durations.ITIs;
trials.ITIs = repmat(shuffle(perBlockITIs)', numTrials / length(perBlockITIs), 1);
% TODO: Extract helper function to add a constant value in a table column

settings.game.trials = trials(1:3, :);

%% Set up window
% TODO: Conditional on provided `settings.device.screenDims`?
[settings.device.windowPtr, settings.device.screenDims] = ...
  Screen('OpenWindow', settings.device.screenId, ...
  settings.background.color);

%% Display blocks
% Option A: Iterate over blocks, passing to runBlock all it'll need in a loop
% Option B: Run each block with separate settings; handle any prompts / continuations here, or pass different callbacks
% Option C: Run things trial-by-trial, passing different settings to each
% Option D: Run down a table of trials, each with a "block type", and let runTrial handle each

%% Option B
% Need to:
% 1. pass the per-block function the trial properties
% 2. specify the kind of setting the trials have, to save
settings.game.block.kind = 'Gains';
settings.game.trialFn = @RA_drawTrial;
settings.reference.format = '$%d';
settings.lottery.stakes.format = '$%d';
% settings.game.stakes = [50 80 110];
% settings.game.fails = 0; % but could be a 1xn matrix
% settings.game.reference = 5; % but could be a 1xn matrix
% settings.game.probs = [.6 .5 .30];
% settings.game.ambigs = [0 .5 0];
% settings.game.ITIs  = [2 4 2];
% settings.game.colors = [1 2 1];
% settings.game.numTrials = length(settings.game.stakes); % FIXME: Should be the longest of the above?

% TODO: `settings` should include a pre-trial and post-trial callback function (to e.g. display block number)
Data = runBlock(Data, settings);
% TODO: Should runBlock be expected to give Data back?

Screen('CloseAll');
end

function arr = shuffle(arr)
  newOrder = randperm(length(arr));
  arr = arr(newOrder);
end
