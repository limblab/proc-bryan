function analogdata = add_timeframe(analogdata);

  analogdata.timeframe = analogdata.timestamps(1) + single(0:1/analogdata.freq(1):(length(analogdata.data)-1)/analogdata.freq(1));

  