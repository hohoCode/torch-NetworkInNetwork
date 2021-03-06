----------------------------------------------------------------------
-- This script implements a test procedure, to report accuracy
-- on the test data. Nothing fancy here...
--
-- Clement Farabet
----------------------------------------------------------------------

require 'optim'   -- an optimization package, for online and batch methods

----------------------------------------------------------------------
print '==> defining some tools'

-- model:
local t = require 'model'
local model = t.model
local loss = t.loss
local dropout = t.dropout

-- classes
local classes = {'airplane', 'automobile', 'bird', 'cat',
           'deer', 'dog', 'frog', 'horse', 'ship', 'truck'}

-- This matrix records the current confusion across classes
local confusion = optim.ConfusionMatrix(classes)

-- Logger:
local testLogger = optim.Logger(paths.concat(opt.save, 'test.log'))

-- Batch test:
local inputs = torch.CudaTensor(opt.batchSize,3,32,32)
local targets = torch.CudaTensor(opt.batchSize)


----------------------------------------------------------------------
print '==> defining test procedure'

-- test function
function test(testData)
   -- local vars
   local time = sys.clock()

   -- dropout -> off
   for _,d in ipairs(dropout) do
      d.train = false
   end

   -- test over test data
   print('==> testing on test set:')
   for t = 1,testData:size(),opt.batchSize do
      -- disp progress
       xlua.progress(t, testData:size())

      -- batch fits?
      if (t + opt.batchSize - 1) > testData:size() then
         break
      end

      -- create mini batch
      local idx = 1
      for i = t,t+opt.batchSize-1 do
         inputs[idx] = testData.data[i]
         targets[idx] = testData.labels[i]
         idx = idx + 1
      end

      -- test sample
      local preds = model:forward(inputs)

      -- confusion
      for i = 1,opt.batchSize do
         confusion:add(preds[i], targets[i])
      end
   end

   -- timing
   time = sys.clock() - time
   time = time / testData:size()
   print("\n==> time to test 1 sample = " .. (time*1000) .. 'ms')

   -- print confusion matrix
   print(tostring(confusion))

   -- update log/plot
   testLogger:add{['% mean class accuracy (test set)'] = confusion.totalValid * 100}

   confusion:zero()
end

-- Export:
return test

