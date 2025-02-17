WITH 
token_volume AS (
    -- tokens sent
    SELECT 
        "from" AS address,
        SUM(amount_usd) AS amount,
        count(unique_key) AS transfer_count
    FROM 
        tokens.transfers tfr
    WHERE 
        block_date > date(timestamp '{{date}}')
        AND contract_address = {{token_address}}
    GROUP BY 1
    
    UNION ALL
    
    -- tokens received
    SELECT 
        tfr.to AS address,
        SUM(amount_usd) AS amount,
        count(unique_key) AS transfer_count
    FROM 
        tokens.transfers tfr
    WHERE 
        block_date > date(timestamp '{{date}}')
        AND contract_address = {{token_address}}
    GROUP BY 1
),

token_holders_flow AS (
    SELECT
        address,
        SUM(amount) AS total_volume,
        SUM(transfer_count) AS total_transfer_count
    FROM token_volume
    GROUP BY 1
)

,agg_token_holders_flow AS (
    SELECT
        address,
        total_volume,
        ROW_NUMBER() OVER (ORDER BY total_volume desc, total_transfer_count desc, address) AS rank
    FROM
    token_holders_flow
    WHERE total_volume > 0
)

,top_{{num_wallets}} AS (
    SELECT
        address,
        total_volume,
        rank
    FROM 
        agg_token_holders_flow
    WHERE
        rank <= {{num_wallets}}
)

,top_wallets_flow AS (
    SELECT
        "from" AS from_address,
        tfr.to AS to_address,
        coalesce(label_from.rank, 999999999) as flow_rank_from,
        coalesce(label_to.rank, 999999999) as flow_rank_to,
        SUM(amount_usd) AS total_flow_amount
    FROM 
      tokens.transfers tfr
    JOIN 
        tokens.erc20 erc 
        ON tfr.contract_address = erc.contract_address
        AND tfr.contract_address = {{token_address}}
    JOIN
        top_{{num_wallets}} top
        ON (tfr."from" = top.address OR 
            tfr.to = top.address)
    LEFT JOIN
        top_{{num_wallets}} label_from
        ON tfr."from" = label_from.address
    LEFT JOIN
        top_{{num_wallets}} label_to
        ON tfr.to = label_to.address

    WHERE 
        tfr.block_date > date(timestamp '{{date}}')
        AND tfr.contract_address = {{token_address}}
        AND tfr.blockchain = '{{chain}}'
    GROUP BY 1, 2, 3, 4
),

labels_flow AS (
    SELECT
        sum(top.total_flow_amount) AS total_flow_amount,
        min(top.flow_rank_from) AS flow_rank_from,
        min(top.flow_rank_to) AS flow_rank_to,
        COALESCE(label.custody_owner, 
                 label.owner_key, 
                 case when ens.name is not null or ens.name = '' then 'Individual' else null end, 
                 'Unknown') AS label_name_from,
        COALESCE(label2.custody_owner, 
                 label2.owner_key, 
                 case when ens2.name is not null or ens2.name = '' then 'Individual' else null end, 
                 'Unknown') AS label_name_to
    FROM
        top_wallets_flow top
    LEFT JOIN
        labels.owner_addresses AS label
        ON label.blockchain = '{{chain}}'
        AND top.from_address = label.address
    LEFT JOIN
        labels.ens AS ens
        ON ens.blockchain = '{{chain}}'
        AND top.from_address = ens.address
    LEFT JOIN
        labels.owner_addresses AS label2
        ON label2.blockchain = '{{chain}}'
        AND top.to_address = label2.address
    LEFT JOIN
        labels.ens AS ens2
        ON ens2.blockchain = '{{chain}}'
        AND top.to_address = ens2.address
    group by 4,5
)

SELECT
*
FROM
labels_flow
WHERE
label_name_from != label_name_to
ORDER BY flow_rank_from, flow_rank_to
